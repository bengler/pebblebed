# Extends Sinatra for maximum pebble pleasure
require 'pebblebed'

module Sinatra
  module Pebblebed
    module Helpers
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

      def current_identity
        return nil unless current_session
        return @identity if @identity_checked
        @identity_checked = true
        if cache_current_identity?
          @identity = ::Pebblebed.memcached.fetch("identity-for-session-#{current_session}", :ttl => 60) do
            pebbles.checkpoint.get("/identities/me")[:identity]
          end
        else
          @identity = pebbles.checkpoint.get("/identities/me")[:identity]
        end
      end

      def cache_current_identity?
        settings.respond_to?(:cache_current_identity) && settings.cache_current_identity
      end

      def require_identity
        unless current_identity.respond_to?(:id)
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

      app.error ::Pebblebed::HttpNotFoundError do
        [404,  env['sinatra.error'].message]
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
