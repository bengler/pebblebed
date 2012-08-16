require 'active_support/inflector'

module Pebblebed 
  class Connector 
    attr_accessor :key
    def initialize(key = nil, url_opts = {})
      @key = key
      @clients = {}
      @url_opts = url_opts
    end

    def [](service)
      client_class = self.class.client_class_for(service)
      (@clients[service.to_sym] ||= client_class.new(@key, Pebblebed.root_url_for(service.to_s, @url_opts)))
    end

    # Returns a quorum client that talks to the provided list of 
    # pebbles all at once. The result is a hash of services and their
    # responses. If any service returned an error, their entry
    # in the hash will be an HttpError object.
    def quorum(services = nil, session_key = nil)
      QuorumClient.new(services || Pebblebed.services, session_key)
    end
  
      
    def parts
      @@parts ||= Pebblebed::Parts.new(self)
    end

    def self.client_class_for(service)
      class_name = ActiveSupport::Inflector.classify(service)+'Client'
      begin
        Pebblebed.const_get(class_name)
      rescue NameError
        GenericClient
      end
    end
  end
end