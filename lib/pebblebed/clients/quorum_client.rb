require 'deepstruct'
require 'futurevalue'

# A client that talks to a number of clients all at on
module Pebblebed
  class QuorumClient < AbstractClient
    def initialize(services, session_key)
      @clients = Hash[services.map do |service|
        [service, Pebblebed::GenericClient.new(session_key, Pebblebed.root_url_for(service))]
      end]
    end

    def perform(method, url = '', params = {}, &block)
      # Using Future::Value perform the full quorum in parallel
      results = @clients.map do |service, client|
        response = [service]
        response << Future::Value.new do 
          begin
            client.perform(method, url, params, &block) 
          rescue HttpError => e
            e
          end
        end
        response
      end
      # Unwrap future values and thereby joining all threads
      Hash[results.map { |service, response| [service, response.value]}]
    end
  end
end