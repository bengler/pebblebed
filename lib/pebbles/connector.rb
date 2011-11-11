require 'active_support/inflector'

module Pebbles 
  class Connector 
    def initialize(key = nil, url_opts = {})
      @key = key
      @clients = {}
      @url_opts = url_opts
    end

    def [](service)
      client_class = self.class.client_class_for(service)
      (@clients[service.to_sym] ||= client_class.new(@key, Pebbles.root_url_for(service.to_s, @url_opts)))
    end

    def self.client_class_for(service)
      class_name = ActiveSupport::Inflector.classify(service)+'Client'
      begin
        Pebbles.const_get(class_name)
      rescue NameError
        GenericClient
      end
    end
  end
end