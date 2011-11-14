require 'deepstruct'

module Pebbles
  class GenericClient
    def initialize(session_key, root_url)
      @root_url = root_url  
      @root_url = URI(@root_url) unless @root_url.is_a?(URI::HTTP)
      @session_key = session_key
    end

    def perform(method, url = '', params = {}, &block)
      begin
        result = Pebbles::Http.send(method, service_url(url), service_params(params), &block)
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

    def service_url(url)
      result = @root_url.dup
      result.path = result.path.sub(/\/+$/, "") + url
      result
    end

    def service_params(params)
      params ||= {}
      params['session'] = @session_key if @session_key
      params
    end

  end
end