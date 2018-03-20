require 'absolute_time'
require 'pebblebed'

# Extends Sinatra for maximum pebble pleasure
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
        if params[:session]
          LOGGER.info("PebbleBedLog.current_session using params[:session]: #{params.inspect}")
          return params[:session]
        else
          LOGGER.info("PebbleBedLog.current_session using cookie: #{request.cookies[::Pebblebed.session_cookie]}")
          return request.cookies[::Pebblebed.session_cookie]
        end
      end
      alias :checkpoint_session :current_session

      def pebbles
        connector_options = {
          :host => ::Pebblebed.host || request.host || ::Pebblebed.default_host,
          :scheme => ::Pebblebed.scheme || request.scheme
        }
        LOGGER.info("PebbleBedLog.pebbles using session: #{checkpoint_session}")
        ::Pebblebed::Connector.new(checkpoint_session, connector_options)
      end

      def current_identity_data
        return DeepStruct.wrap({}) unless current_session
        if @current_identity_data
          LOGGER.info("PebbleBedLog.current_identity_data: #{@current_identity_data.inspect}")
        else
          LOGGER.info("PebbleBedLog.current_identity_data unset, fetching")
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

      def require_identity
        unless current_identity
          logger.warn "Current session (#{current_session}) has no identity"
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
        collection = collection.limit(limit+1).offset(offset).to_a
        last_page = (collection.length <= limit)
        metadata = {:limit => limit, :offset => offset, :last_page => last_page}
        collection = collection[0..limit-1]
        [collection, metadata]
      end
    end

    def self.registered(app)
      app.helpers(Sinatra::Pebblebed::Helpers)
      app.before do
        @_start_time = AbsoluteTime.now
      end
      app.after do
        if (start_time = @_start_time)
          headers 'X-Timing' => ((AbsoluteTime.now - start_time) * 1000).to_i.to_s
        end
      end
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
