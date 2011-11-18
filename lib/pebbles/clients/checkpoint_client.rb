module Pebbles 
  class CheckpointClient < Pebbles::GenericClient
    def me
      return @identity if @identity_checked
      @identity_checked = true
      @identity = get("/identities/me")[:identity]
    end

    def to_cache_key(id)
      "identity:#{id}"
    end

    def find_identities(ids)

      result = []
      uncached = ids

      if Pebbles.memcached
        cache_keys = ids.collect {|i| to_cache_key i}
        result = Hash[Pebbles.memcached.get_multi(*cache_keys).map do |key, value|
                  identity = DeepStruct.wrap(Yajl::Parser.parse(value)) unless value.nil?
                  /identity:(?<id>\d+)/ =~ key # yup, this is ugly, but an easy hack to get the actual identity id we are trying to retrieve
                  [id.to_i, identity]
                end]
        uncached = ids-result.keys
      end

      if uncached.size > 0
        request = get("/identities/#{uncached.join(',')}#{',' unless uncached.size > 1}")
        uncached.each do |id|
          found = request.identities.find {|i| i.identity.respond_to?(:id) && i.identity.id == id}
          identity = found && found.identity || nil
          result[id] = identity
          Pebbles.memcached.set(to_cache_key(id), identity.try(:to_json), ttl=60*15) if Pebbles.memcached
        end
      end
      return DeepStruct.wrap(result)
    end

    def god?
      me.god if me
    end
  end
end