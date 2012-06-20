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
        raise ArgumentError.new(':event is required') unless options[:event]
        raise ArgumentError.new(':uid is required') unless options[:uid]

        uid = Pebblebed::Uid.new(options[:uid])
        key = [options[:event], uid.klass, uid.path].compact
        key.join('._.')
      end

      def queries(options = {})
        event = querify(options[:event]).split('|')
        path = querify(options[:path])
        klass = querify(options[:klass])

        qx = []
        qx << [event, klass, path].join('._.')
        qx
      end

      def combine_queries()
      end

      def querify(query)
        (query || '#').gsub('**', '#')
      end
    end

  end
end
