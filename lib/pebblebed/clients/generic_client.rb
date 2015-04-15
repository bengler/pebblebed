require 'deepstruct'

module Pebblebed
  class GenericClient < AbstractClient
    def initialize(session_key, root_url)
      @root_url = root_url  
      @root_url = URI(@root_url) unless @root_url.is_a?(URI::HTTP)
      @session_key = session_key
    end

    def perform(method, url = '', params = {}, &block)
      begin
        result = Pebblebed::Http.send(method, service_url(url), service_params(params), &block)
        return DeepStruct.wrap(JSON.parse(result.body))
      rescue JSON::ParserError => e
        if e.message =~ /^lexical error: invalid bytes in UTF8 string/
          raise
        else
          # Treat as non-JSON
          return result.body
        end
      end
    end

    def service_url(url, params = nil)
      result = @root_url.dup
      result.path = result.path.sub(/\/+$/, "") + url
      if params
        result.query << '&' if result.query
        result.query ||= ''
        result.query << if params.is_a?(Hash)
          params.entries.map { |k, v| CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s) }.join('&')
        else
          params
        end
      end
      result
    end

    def service_params(params)
      if (key = @session_key) and (params.nil? or not params[:session])
        if params
          params = params.dup  # Make sure we don't modify it
        else
          params = {}
        end
        params['session'] = key
      end
      params
    end

  end
end