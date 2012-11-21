# A class that helps 
module Pebblebed
  module Security
    class Client
      IDENTITY_MEMBERSHIPS_TTL = 10*60

      def initialize(connector)
        @connector = connector
        @access_data = {} # Memoized identity access data records
      end

      # Returns an object representing the current access data for a given identity
      def access_data_for(identity)
        identity = identity.id unless identity.is_a?(Numeric)
        return @access_data[identity] if @access_data[identity]
        membership_data = fetch_membership_data_for(identity)
        result = Pebblebed::Security::AccessData.new(membership_data)
        @access_data[identity] = result
        result
      end

      private

      def fetch_membership_data_for(identity)
        result = Pebblebed.memcached.fetch("identity_membership_data:#{identity}", IDENTITY_MEMBERSHIPS_TTL) do
          @connector.checkpoint.get("/identities/#{identity}/memberships").to_json
        end
        JSON.parse(result)
      end

    end
  end
end
