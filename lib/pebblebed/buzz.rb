require 'zmq'
require 'json'

module Pebblebed
  class Buzz

    def self.should_enable?
      !!(::Pebblebed.name && ::Pebblebed::buzz_endpoints)
    end

    def initialize(app)
      @app = app
      @name = ::Pebblebed.name
      if @name and (endpoints = ::Pebblebed::buzz_endpoints)
        context = ZMQ::Context.new
        @socket = context.socket(:PUB)
        @socket.verbose = true if (ENV['RACK_ENV'] || 'development') == 'development'
        endpoints.each do |endpoint|
          @socket.bind(endpoint)
        end
        @socket.linger = 1
      end
    end

    def call(env)
      result = @app.call(env)
      if @socket
        event = {
          fromId: env['HTTP_PEBBLE'] || 'unknown',
          toId: @name,
          ua: env['HTTP_USER_AGENT'],
          # FIXME: Only allow trusted forwarders
          ip: env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR']
        }

        @socket.sendm("buzz.edge")
        @socket.send(JSON.dump(event))
      end
      result
    end

  end
end
