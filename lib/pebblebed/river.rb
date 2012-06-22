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

        @exchange = nil if @exchange && @exchange.name != name
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

      def random_name
        Digest::SHA1.hexdigest(rand(10 ** 10).to_s)
      end

      def purge
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
