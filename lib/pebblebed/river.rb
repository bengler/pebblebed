require 'json'
require 'bunny'

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
        bunny.start unless bunny.connected?
      end

      def disconnect
        bunny.stop
      end

      def publish(options = {})
        connect
        key = route(options)
        exchange.publish(options.to_json, :persistent => true, :key => key)
      end

      def exchange
        connect

        @exchange ||= bunny.exchange('pebblebed.river', :type => :topic, :durable => :true)
      end

      def queue_me(name = nil, options = {})
        connect

        name ||= random_name
        key = options[:key] || '#'
        queue = bunny.queue(name)
        queue.bind(exchange.name, :key => key)
        queue
      end

      def random_name
        Digest::SHA1.hexdigest(rand(10 ** 10).to_s)
      end

      def purge
        q = queue_me
        q.purge
        q.delete
        true
      end

      def route(options)
        uid = Pebblebed::Uid.new(options[:uid])
        key = []
        key << options[:event]
        key << uid.path
        key << uid.klass
        key.compact.join('._.')
      end
    end

  end
end
