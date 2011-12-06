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

  def self.config(&block)
    Builder.new.send(:instance_eval, &block)
  end

  def self.require_service(name, options = {})
    (@services ||= {})[name.to_sym] = options
    Pebblebed::Connector.class_eval <<-END
      def #{name}
        self["#{name}"]
      end
    END
  end

  def self.host
    @host
  end

  def self.host=(value)
    @host = value
  end

  def self.memcached
    @memcached
  end

  def self.memcached=(value)
    @memcached = value
  end

  def self.version_of(service)
    return 1 unless @services && @services[service.to_sym]
    @services[service.to_sym][:version] || 1
  end

  def self.root_url_for(service, url_opts={})
    URI("http://#{url_opts[:host] || host}/api/#{service}/v#{version_of(service)}/")
  end
end
