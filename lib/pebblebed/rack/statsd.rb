require 'statsd'

module Pebblebed
  module Rack

    # Rack handler that records metrics in Statsd.
    class Statsd

      def initialize(app)
        @app = app
        @statsd = ::Pebblebed.statsd
      end

      def call(env)
        result = nil
        elapsed_time = (Benchmark.realtime {
          result = @app.call(env)
        })
        @statsd.increment('requests_total')
        @statsd.timing('request_time', elapsed_time)
        result
      end

      attr_accessor :statsd, :app

    end

  end
end