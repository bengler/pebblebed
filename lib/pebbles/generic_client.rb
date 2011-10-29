module Pebbles
  class GenericClient
    def initialize(session_key, root_url)
      @root_url = root_url.chomp('/')
      @session_key = session_key
    end

    def get(url, params = {})
      params[:session] = @session_key if @session_key
      Pebbles::Http.get_json(@root_url+url, params)
    end
  end
end