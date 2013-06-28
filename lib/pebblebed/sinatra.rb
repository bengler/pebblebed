# Extends Sinatra for maximum pebble pleasure
require 'pebblebed'

module Sinatra
  module Pebblebed
    module Helpers
      # Cache identity for this amount of seconds. TTL will be reset each cache hit,
      # so real TTL might be much longer than this.
      IDENTITY_CACHE_TTL = 7

      # Render the markup for a part. A partspec takes the form
      # "<kit>.<partname>", e.g. "base.post"
      def part(partspec, params = {})
        params[:session] ||= current_session
        pebbles.parts.markup(partspec, params)
      end

      def parts_script_include_tags
        @script_include_tags ||= pebbles.parts.javascript_urls.map do |url|
          "<script src=\"#{url.to_s}\"></script>"
        end.join
      end

      def parts_stylesheet_include_tags
        @stylesheet_include_tags ||= pebbles.parts.stylesheet_urls.map do |url|
          "<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"#{url.to_s}\">"
        end.join
      end

      def current_session
        params[:session] || request.cookies['checkpoint.session']
      end
      alias :checkpoint_session :current_session

      def pebbles
        @pebbles ||= ::Pebblebed::Connector.new(checkpoint_session, :host => request.host)
      end

      def current_identity_data
        return DeepStruct.wrap({}) unless current_session
        return @current_identity_data if @current_identity_data_fetched
        @current_identity_data_fetched = true
        if cache_current_identity?
          cache_key = "identity-data-for-session-#{current_session}"
          @current_identity_data = ::Pebblebed.memcached.get(cache_key)
          if @current_identity_data
            # Reinstate this line when memcached version >= 1.4.8
            # ::Pebblebed.memcached.touch(cache_key, IDENTITY_CACHE_TTL)
            return @current_identity_data
          end
          @current_identity_data = pebbles.checkpoint.get("/identities/me")
          # Cache identity only if there is an identity in the data returned from checkpoint
          ::Pebblebed.memcached.set(cache_key, @current_identity_data, IDENTITY_CACHE_TTL) if @current_identity_data['identity']
        else
          @current_identity_data = pebbles.checkpoint.get("/identities/me")
        end
        @current_identity_data
      end

      def current_identity
        current_identity_data['identity']
      end

      def current_profile
        current_identity_data['profile']
      end

      def cache_current_identity?
        settings.respond_to?(:cache_current_identity) && settings.cache_current_identity
      end

      def require_identity
        unless current_identity
          halt 403, "No current identity."
        end
      end

      def require_god
        require_identity
        halt 403, "Current identity #{current_identity.id} is not god" unless current_identity.god
      end

      def require_parameters(parameters, *keys)
        missing = keys.map(&:to_s) - (parameters ? parameters.keys : [])
        halt 409, "missing parameters: #{missing.join(', ')}" unless missing.empty?
      end

      def has_access_to_path?(path)
        return false unless current_identity
        return true if current_identity.god and path.split(".")[0] == current_identity.realm
        res = pebbles.checkpoint.get("/identities/#{current_identity.id}/access_to/#{path}")
        res['access'] and res['access']['granted'] == true
      end

      def require_access_to_path(path)
        require_identity        
        halt 403, "Access denied." unless has_access_to_path?(path)
      end

      def require_action_allowed(action, uid, options={})
        require_identity
        uid = ::Pebblebed::Uid.new(uid) if uid.is_a?(String)
        return if current_identity.god and uid.path.split(".")[0] == current_identity.realm
        res = pebbles.checkpoint.post("/callbacks/allowed/#{action}/#{uid}")
        return res['allowed'] if res['allowed'] == true or
          (res['allowed'] == "default" and options[:default])
        halt 403, ":#{action} denied for #{uid} : #{res['reason']}"
      end

      def limit_offset_collection(collection, options)
        limit = (options[:limit] || 20).to_i
        offset = (options[:offset] || 0).to_i
        collection = collection.limit(limit+1).offset(offset)
        last_page = (collection.size <= limit)
        metadata = {:limit => limit, :offset => offset, :last_page => last_page}
        collection = collection[0..limit-1]
        [collection, metadata]
      end
    end

    def self.registered(app)
      app.helpers(Sinatra::Pebblebed::Helpers)
    end

    def declare_pebbles(&block)
      ::Pebblebed.config(&block)
    end

    def i_am(service_name)
      set :service_name, service_name
    end

    ##
    # Adds a before filter to ensure all visitors gets assigned a provisional identity. The options hash takes an
    # optional key "unless" which can be used to specify a lambda/proc that yields true if
    # the request should *not* trigger a redirect to checkpoint
    #
    # TODO: Also implement a guard against infinite redirect loops
    #
    # Usage example:
    #
    #   assign_provisional_identity :unless => lambda {
    #    request.path_info == '/ping' || BotDetector.bot?(request.user_agent)
    #  }
    #
    def assign_provisional_identity(opts={})
      before do
        skip = opts.has_key?(:unless) && instance_exec(&opts[:unless])
        if !skip && current_identity.nil?
          redirect pebbles.checkpoint.service_url("/login/anonymous", :redirect_to => request.path).to_s
        end
      end
    end

  end
end
