require 'deepstruct'

module Pebbles
  class GenericClient
    def initialize(session_key, root_url)
      @root_url = root_url
      @session_key = session_key
    end

    def perform(method, url = '', params = {}, &block)

      params['session'] = @session_key if @session_key

      request_url = @root_url.dup
      request_url.path = request_url.path.sub(/\/+$/, "") + url

      begin
        result = Pebbles::Http.send(method, request_url, params, &block)
        return DeepStruct.wrap(Yajl::Parser.parse(result.body))        
      rescue Yajl::ParseError
        return result.body
      end
    end

    def get(*args, &block)
      perform(:get, *args, &block)
    end

    def post(*args, &block)
      perform(:post, *args, &block)
    end

    def delete(*args, &block)
      perform(:delete, *args, &block)
    end
  end
end