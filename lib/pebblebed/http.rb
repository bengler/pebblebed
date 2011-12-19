# A wrapper for all low level http client stuff

require 'uri'
require 'curl'
require 'yajl'
require 'queryparams'
require 'nokogiri'
require 'pathbuilder'
require 'active_support'

module Pebblebed
  class HttpError < Exception
    attr_reader :status, :message
    def initialize(message, status = nil)
      @message = message
      @status = status      
    end

    def not_found?
      @status_code == 404
    end
  end

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

    def self.get(url = nil, params = nil, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_curl_response(Curl::Easy.perform(url_with_params(url, params)))
    end

    def self.post(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_curl_response(Curl::Easy.http_post(url, *(QueryParams.encode(params).split('&'))))
    end

    def self.put(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_curl_response(Curl::Easy.http_put(url, *(QueryParams.encode(params).split('&'))))
    end

    def self.delete(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)      
      handle_curl_response(Curl::Easy.http_delete(url_with_params(url, params)))
    end

    private

    def self.handle_http_errors(result)
      if result.status >= 400
        errmsg = "Service request to '#{result.url}' failed (#{result.status}):"
        errmsg << extract_error_summary(result.body)
        raise HttpError.new(result.status, ActiveSupport::SafeBuffer.new(errmsg)) 
        # ActiveSupport::SafeBuffer.new is the same as errmsg.html_safe in rails
      end
      result
    end

    def self.handle_curl_response(curl_response)      
      handle_http_errors(CurlResult.new(curl_response))
    end

    def self.url_with_params(url, params)      
      url.query = QueryParams.encode(params || {})
      url.to_s
    end

    def self.url_and_params_from_args(url, params = nil, &block)
      url = URI.parse(url) unless url.is_a?(URI)
      if block_given?
        pathbuilder = PathBuilder.new.send(:instance_eval, &block)
        url = url.dup
        url.path = url.path.chomp("/")+pathbuilder.path
        (params ||= {}).merge!(pathbuilder.params)
      end
      [url, params]
    end

    def self.extract_error_summary(body)
      # Supports Sinatra error pages
      extract = Nokogiri::HTML(body).css('#summary').text.gsub(/\s+/, ' ').strip
      # TODO: Rails?
      return body if extract == ''
      extract
    end

  end
end