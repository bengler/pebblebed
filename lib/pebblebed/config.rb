module Pebblebed
  class Builder
    def host(value)
      Pebblebed.host = value
    end

    def memcached(value)
      Pebblebed.memcached = value
    end

    def service(name, options = {})
      Pebblebed.require_service(name, options)
    end
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

    def host
      @host
    end

    def host=(value)
      @host = value
    end

    def memcached
      raise RuntimeError, "Please set Pebblebed.memcached = <your memcached client>" unless @memcached
      @memcached
    end

    def memcached=(value)
      @memcached = value
    end

    def services
      @services.keys
    end

    def version_of(service)
      return 1 unless @services && @services[service.to_sym]
      @services[service.to_sym][:version] || 1
    end

    def root_url_for(service, url_opts={})
      URI("http://#{url_opts[:host] || host}/api/#{service}/v#{version_of(service)}/")
    end
  end
end
