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

      def url
        @curl_result.url
      end

      def body
        @curl_result.body_str
      end
    end

    def self.handle_http_errors(result)
      raise HttpError, "#{result.status} #{result.body} (from #{result.url})" if result.status >= 400
      result
    end

    def self.get(url = nil, params = nil, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_http_errors(CurlResult.new(Curl::Easy.perform(url_with_params(url, params))))
    end

    def self.post(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_http_errors(CurlResult.new(Curl::Easy.http_post(url, *(QueryParams.encode(params).split('&')))))
    end

    def self.delete(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_http_errors(CurlResult.new(Curl::Easy.http_delete(url_with_params(url, params))))
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