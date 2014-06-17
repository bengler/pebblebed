require 'json'
require 'bunny'
require 'pebblebed/river/subscription'

module Pebblebed
  class River

    class << self
      def route(options)
        raise ArgumentError.new(':event is required') unless options[:event]
        raise ArgumentError.new(':uid is required') unless options[:uid]

        uid = Pebblebed::Uid.new(options[:uid])
        key = [options[:event], uid.klass, uid.path].compact
        key.join('._.')
      end
    end

    def initialize(env = ENV['RACK_ENV'])
      @environment = env || 'development'
    end

    def connected?
      bunny.connected?
    end

    def connect
      unless connected?
        bunny.start
      end
    end

    def disconnect
      bunny.stop if connected?
    end

    def publish(options = {})
      connect

      persistent = options.fetch(:persistent) { true }
      key = self.class.route(options)
      exchange.publish(options.to_json, :persistent => persistent, :key => key)
    end

    def queue(options = {})
      connect

      raise ArgumentError.new 'Queue must be named' unless options[:name]

      queue = channel.queue(options[:name], :durable => true)
      Subscription.new(options).queries.each do |key|
        queue.bind(exchange.name, :key => key)
      end
      queue
    end

    def exchange_name
      unless @exchange_name
        name = 'pebblebed.river'
        name << ".#{environment}" unless production?
        @exchange_name = name
      end
      @exchange_name
    end

    private

    def environment
      @environment
    end

    def bunny
      @bunny ||= Bunny.new
    end

    def production?
      environment == 'production'
    end

    def channel
      connect
      @channel ||= @bunny.create_channel
    end

    def exchange
      connect

      @exchange ||= channel.exchange(exchange_name, :type => :topic, :durable => :true)
    end

  end

end
