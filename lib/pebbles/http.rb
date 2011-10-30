# A wrapper for all low level http client stuff

require 'uri'
require 'curl'
require 'yajl'
require 'queryparams'
require 'pathbuilder'

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

    def self.get(url = nil, params = nil, &block)
      url, params = url_and_params_from_args(url, params, &block)
      result = CurlResult.new(Curl::Easy.perform(url_with_params(url, params)))
      raise HttpError, "#{result.status} #{result.body}" if result.status >= 400
      result
    end

    def self.get_json(*args, &block)      
      Yajl::Parser.parse(get(*args, &block).body)
    end

    def self.post(url, body)
      raise "Not implemented"
    end

    private

    def self.url_with_params(url, params)
      "#{url}?#{QueryParams.encode(params || {})}".chomp('?')
    end

    def self.url_and_params_from_args(url, params = nil, &block)
      if block_given?
        pathbuilder = PathBuilder.new.send(:instance_eval, &block)
        url = url.chomp("/") + pathbuilder.path
        (params ||= {}).merge!(pathbuilder.params)
      end
      [url, params]
    end

  end
end