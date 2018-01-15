module Pebblebed
  class Builder
    def host(value)
      Pebblebed.host = value
    end

    def scheme(value)
      Pebblebed.scheme = value
    end

    def default_host(value)
      Pebblebed.default_host = value
    end

    def memcached(value)
      Pebblebed.memcached = value
    end

    def session_cookie(value)
      Pebblebed.session_cookie = value
    end

    def service(name, options = {})
      Pebblebed.require_service(name, options)
    end

    def base_uri(value)
      Pebblebed.base_uri = value
    end
    alias base_url base_uri
  end

  def self.require_service(name, options = {})
    (@services ||= {})[name.to_sym] = options
    Pebblebed::Connector.class_eval <<-END
      def #{name}
        self["#{name}"]
      end
    END
  end

  class << self
    def config(&block)
      Builder.new.send(:instance_eval, &block)
    end

    attr_accessor :host, :default_host, :scheme

    def memcached
      raise RuntimeError, "Please set Pebblebed.memcached = <your memcached client>" unless @memcached
      @memcached
    end

    def memcached=(value)
      @memcached = value
    end

    def session_cookie
      @session_cookie || 'checkpoint.session'
    end

    def session_cookie=(value)
      @session_cookie = value
    end

    def services
      @services.keys
    end

    def base_uri
      @base_uri
    end
    alias base_url base_uri

    def base_uri=(value)
      @base_uri = value
    end
    alias base_url= base_uri=

    def version_of(service)
      return 1 unless @services && @services[service.to_sym]
      @services[service.to_sym][:version] || 1
    end

    def path_of(service)
      @services[service.to_sym][:path] || "/api/#{service}"
    end

    def root_url_for(service, url_opts = {})
      url_opts = {host: (@services[service.to_sym] || {})[:host]}.merge(url_opts)
      URI.join(base_url_for(url_opts), "#{path_of(service)}/v#{version_of(service)}/")
    end

    def base_url_for(url_opts)
      raise RuntimeError, "Please specify only one of host & base_uri" if url_opts[:host] && (url_opts[:base_uri] || url_opts[:base_url])
      [:base_uri, :base_url].each do |key|
        return url_opts[key] if url_opts[key]
      end
      scheme = url_opts[:scheme] || ::Pebblebed.scheme || 'http'
      return "#{scheme}://#{url_opts[:host]}" if url_opts[:host]
      base_uri || "#{scheme}://#{host}"
    end
  end
end
