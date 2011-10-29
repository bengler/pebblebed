# A wrapper for all low level http client stuff

require 'uri'
require 'curl'
require 'yajl'
require 'queryparams'

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

    def self.get(url, params)
      result = CurlResult.new(Curl::Easy.perform(url_with_params(url, params)))
      raise HttpError, "#{result.status} #{result.body}" if result.status >= 400
      result
    end

    def self.get_json(*args)      
      Yajl::Parser.parse(get(*args).body)
    end

    def self.post(url, body)
      raise "Not implemented"
    end

    def self.url_with_params(url, params)
      "#{url}?#{QueryParams.encode(params || {})}".chomp('?')
    end

  end
end