module Pebbles 
  class Connector 
    def initialize(key = nil, url_opts = {})
      @key = key
      @clients = {}
      @url_opts = url_opts
    end

    def [](service)
      (@clients[service.to_sym] ||= GenericClient.new(@key, Pebbles.root_url_for(service.to_s, @url_opts)))
    end

    def me
      return @identity if @identity_checked
      attributes = self['checkpoint'].get "/identities/me"
      @identity_checked = true
      @identity = Pebbles::Identity.new(attributes['identity']) if attributes['identity']      
    end

    def god?
      self.god == true
    end
  end
end