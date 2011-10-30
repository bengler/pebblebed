require 'deepstruct'

module Pebbles
  class GenericClient
    def initialize(session_key, root_url)
      @root_url = root_url.chomp('/')
      @session_key = session_key
    end

    def get(url = '', params = {}, &block)
      puts block.inspect
      params[:session] = @session_key if @session_key
      DeepStruct.wrap(Pebbles::Http.get_json(@root_url+url, params, &block))
    end
  end
end