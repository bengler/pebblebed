module Pebbles
  class Builder
    def host(value)
      Pebbles.host = value
    end

    def redis(value)
      Pebbles.redis = value
    end

    def service(name, options = {})
      Pebbles.require_service(name, options)
    end
  end

  def self.config(&block)
    Builder.new.send(:instance_eval, &block)
  end

  def self.require_service(name, options = {})
    (@services ||= {})[name.to_sym] = options
    Pebbles::Connector.class_eval <<-END
      def #{name}
        self["#{name}"]
      end
    END
  end

  def self.host
    @host || 'pebbles.dev'
  end

  def self.host=(value)
    @host = value
  end

  def self.redis
    @redis
  end

  def self.redis=(value)
    @redis = value
  end

  def self.version_of(service)
    return 1 unless @services && @services[service.to_sym]
    @services[service.to_sym][:version] || 1
  end

  def self.root_url_for(service, url_opts={})
    host = url_opts[:host] if url_opts.has_key?(:host)
    URI("http://#{host}/api/#{service}/v#{version_of(service)}/")
  end
end
