module Pebblebed 
  class CheckpointClient < Pebblebed::GenericClient
    def me
      return @identity if @identity_checked
      @identity_checked = true
      @identity = get("/identities/me")[:identity]
    end

    # Given a list of identity IDs it returns each identity or an empty hash for identities that doesnt exists.
    # If pebbles are configured with memcached, results will be cached.
    # Params: ids a list of identities
    def find_identities(ids)

      result = {}
      request = get("/identities/#{ids.join(',')},")
      ids.each_with_index do |id, i|
        identity = request.identities[i].identity.unwrap
        result[id] = identity
      end
      return DeepStruct.wrap(ids.collect {|id| result[id]})
    end

    def god?
      me.god if me
    end
  end
end
