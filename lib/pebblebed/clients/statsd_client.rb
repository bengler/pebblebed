require 'benchmark'
require 'statsd'

module Pebblebed

  # Client that wraps another client, reporting metrics about calls to Statsd.
  class StatsdClient < AbstractClient

    def initialize(service_name, client, statsd = nil)
      @service_name = service_name
      @client = client
      @statsd = statsd || ::Pebblebed.statsd
    end

    def perform(method, url = '', params = {}, &block)
      statsd = @statsd

      result = nil
      elapsed_time = (Benchmark.realtime {
        result = @client.perform(method, url, params, &block)
      } * 1000).round

      statsd.timing('client_calls', elapsed_time)
      statsd.timing("client_calls_to_#{@service_name}", elapsed_time)

      statsd.increment('client_calls')
      statsd.increment("client_calls_to_#{@service_name}")

      result
    end

    def service_url(*args)
      @client.service_url(*args)
    end

    def service_params(*args)
      @client.service_params(*args)
    end

    attr_reader :service_name
    attr_reader :client

  end

end