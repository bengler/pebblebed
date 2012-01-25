require 'deepstruct'

module Pebblebed
  class AbstractClient
    def perform(method, url = '', params = {}, &block)
      raise NotImplementedError
    end

    def get(*args, &block)
      perform(:get, *args, &block)
    end

    def post(*args, &block)
      perform(:post, *args, &block)
    end

    def put(*args, &block)
      perform(:put, *args, &block)
    end

    def delete(*args, &block)
      perform(:delete, *args, &block)
    end
  end
end