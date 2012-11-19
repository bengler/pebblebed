# Listens to security configuration updates and lets the client application
# register custom handlers for each event.
module Pebblebed
  module Security
    class Listener

      def initialize(options)
        @app_name = options[:app_name]
        @handlers = {:access_group => {},
          :access_group_membership => {},
          :access_group_subtree => {}}
      end

      def start
        @thread ||= Thread.new do
          process
        end
      end

      def stop
        @thread.kill if @thread
        @thread = nil
      end

      def on_group_declared(&block)
        @handlers[:access_group][:create] = block
        @handlers[:access_group][:update] = block
      end

      def on_group_removed(&block)
        @handlers[:access_group][:delete] = block
      end

      def on_subtree_declared(&block)
        @handlers[:access_group_subtree][:create] = block
        @handlers[:access_group_subtree][:update] = block
      end

      def on_subtree_removed(&block)
        @handlers[:access_group_subtree][:delete] = block
      end

      def on_membership_declared(&block)
        @handlers[:access_group_membership][:create] = block
        @handlers[:access_group_membership][:update] = block
      end

      def on_membership_removed(&block)
        @handlers[:access_group_membership][:delete] = block
      end

      private

      # Subscribe to queue and handle incoming messages
      def process
        river = Pebblebed::River.new
        queue_options =  {
          :name => "#{@app_name}.security_listener",
          :path => '**',
          :klass => 'access_group|access_group_membership|access_group_subtree',
          :event => '**',
          :interval => 1
        }
        queue = river.queue queue_options
        queue.subscribe(:ack => true) do |message|
          consider message
        end
      end

      # Parse an incoming message and pass it on
      def consider(message)
        payload = JSON.parse(message[:payload])
        event = payload['event']
        attributes = payload['attributes']
        klass = Pebblebed::Uid.raw_parse(payload['uid']).first
        handle(event, klass, attributes)
      end

      # Determines the correct event handler for the message and calls it
      def handle(event, klass, attributes)
        event_handler = @handlers[klass.to_sym][event.to_sym]
        return unless event_handler
        case klass
        when 'access_group'
          event_handler.call(:id => attributes['id'], :label => attributes['label'])
        when 'access_group_membership'
          event_handler.call(:group_id => attributes['group_id'],
            :identity_id => attributes['identity_id'])
        when 'access_group_subtree'
          event_handler.call(:group_id => attributes['group_id'],
            :location => attributes['location'])
        end
      end
    end
  end
end
