class Pebbles::Identity  

  class << self
    def connect_to_redis(redis = nil)
      @redis = redis || Redis.new
    end

    def find(id)

    end

    def current(request)

    end
  end
  
end