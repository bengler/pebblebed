require 'uri'
require 'curl'
require 'yajl-ruby'

module Pebbles
  class HttpError < Exception; end

  class ClientError < HttpError; end

  class BadRequest < ClientError; end 
  
  module Http
    class CurlResult
      def initialize(curl_result)
        @curl_result = curl_result
      end

      def status
        @curl_result.response_code
      end

      def body
        @curl_result.body_str
      end
    end

    def self.get(url)
      result = CurlResult.new(Curl::Easy.perform(url))
      raise HttpError, "#{result.status_code} #{result.body}" if result.status_code >= 400
      result
    end

    def self.get_json(url)      
      Yajl::HttpStream.get(URI.parse(url))
    end

    def self.post(url, body)
      raise "Not implemented"
    end
  end
end