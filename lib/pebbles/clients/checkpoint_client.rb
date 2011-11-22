module Pebbles 
  class CheckpointClient < Pebbles::GenericClient
    def me
      return @identity if @identity_checked
      @identity_checked = true
      @identity = get("/identities/me")[:identity]
    end

    def cache_key_for_identity_id(id)
      "identity:#{id}"
    end

    # Given a list of identity IDs it returns each identity or an empty hash for identities that doesnt exists.
    # If pebbles are configured with memcached, results will be cached.
    # Params: ids a list of identities
    def find_identities(ids)

      result = {}
      uncached = ids

      if Pebbles.memcached
        cache_keys = ids.collect {|id| cache_key_for_identity_id(id) }
        result = Hash[Pebbles.memcached.get_multi(*cache_keys).map do |key, identity|
                  /identity:(?<id>\d+)/ =~ key # yup, this is ugly, but an easy hack to get the actual identity id we are trying to retrieve
                  [id.to_i, identity]
                end]
        uncached = ids-result.keys
      end

      if uncached.size > 0
        request = get("/identities/#{uncached.join(',')},")
        uncached.each_with_index do |id, i|
          identity = request.identities[i].identity.unwrap
          result[id] = identity
          Pebbles.memcached.set(cache_key_for_identity_id(id), identity, ttl=60*15) if Pebbles.memcached
        end
      end
      return DeepStruct.wrap(ids.collect {|id| result[id]})
    end

    def god?
      me.god if me
    end
  end
end