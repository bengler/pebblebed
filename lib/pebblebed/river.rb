require 'json'
require 'bunny'
require 'pebblebed/river/subscription'

module Pebblebed
  module River

    class << self

      def bunny
        @bunny ||= Bunny.new
      end

      def connected?
        bunny.connected?
      end

      def connect
        unless bunny.connected?
          bunny.start
          bunny.qos
        end
      end

      def disconnect
        bunny.stop if bunny.connected?
      end

      def publish(options = {})
        connect

        persistent = options.fetch(:persistent) { true }

        key = route(options)
        exchange.publish(options.to_json, :persistent => persistent, :key => key)
      end

      def exchange(env = ENV['RACK_ENV'])
        connect

        name = 'pebblebed.river'
        unless env == 'production'
          name << ".#{env}"
        end

        if @exchange && @exchange.name != name
          raise RuntimeError.new 'The river name changed. Are you sure you are in the right environment?'
        end
        @exchange ||= bunny.exchange(name, :type => :topic, :durable => :true)
      end

      def queue_me(options = {})
        connect

        raise ArgumentError.new 'Queue must be named' unless options[:name]

        queue = bunny.queue(options[:name], :durable => true)
        Subscription.new(options).queries.each do |key|
          queue.bind(exchange.name, :key => key)
        end
        queue
      end

      def purge
        if ENV['RACK_ENV'] == 'production'
          raise RuntimeError.new('Only God and root can purge in production. And they need to use rabbitmq-cli.')
        end
        q = queue_me(:name => 'purge_queue')
        q.purge
        q.delete
        true
      end

      def route(options)
        raise ArgumentError.new(':event is required') unless options[:event]
        raise ArgumentError.new(':uid is required') unless options[:uid]

        uid = Pebblebed::Uid.new(options[:uid])
        key = [options[:event], uid.klass, uid.path].compact
        key.join('._.')
      end

    end

  end
end
