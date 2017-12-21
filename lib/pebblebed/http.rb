# A wrapper for all low level http client stuff

require 'uri'
require 'curl'
require 'yajl/json_gem'
require 'queryparams'
require 'nokogiri'
require 'pathbuilder'
require 'active_support'

module Pebblebed
  class HttpError < StandardError
    attr_reader :status, :message, :response

    def initialize(message, status = nil, response = nil)
      @message = message
      @status = status
      @response = response
    end

    def not_found?
      @status_code == 404
    end

    def to_s
      "#<#{self.class.name} #{@status} #{message}>"
    end

    def inspect
      to_s
    end
  end

  class HttpNotFoundError < HttpError

  end

  module Http

    class Response
      def initialize(easy)
        @body = easy.body_str
        # We parse it ourselves because Curl::Easy fails when there's no text message
        @status = easy.header_str.scan(/HTTP\/\d\.\d\s(\d+)\s/).map(&:first).last.to_i
        @url = easy.url
      end

      attr_reader :body, :status, :url
    end

    def self.get(url = nil, params = nil, &block)
      url, params = url_and_params_from_args(url, params, &block)
      return with_curl { |easy|
        easy.url = url_with_params(url, params)
        easy.follow_location = true
        easy.http_get
      }
    end

    def self.post(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      content_type, body = serialize_params(params)
      return with_curl { |easy|
        easy.url = url.to_s
        easy.follow_location = true
        easy.headers['Accept'] = 'application/json'
        easy.headers['Content-Type'] = content_type
        easy.http_post(body)
      }
    end

    def self.put(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      content_type, body = serialize_params(params)
      return with_curl { |easy|
        easy.url = url.to_s
        easy.follow_location = true
        easy.headers['Accept'] = 'application/json'
        easy.headers['Content-Type'] = content_type
        easy.http_put(body)
      }
    end

    def self.delete(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      return with_curl { |easy|
        easy.follow_location = true
        easy.url = url_with_params(url, params)
        easy.http_delete
      }
    end

    private

    def self.serialize_params(params)
      if String === params
        content_type, body = 'text/plain', params
      else
        content_type, body = 'application/json', JSON.dump(params)
      end
      if body.respond_to?(:encoding) and body.encoding != Encoding::UTF_8
        content_type << "; charset=#{body.encoding}"
      end
      return content_type, body
    end

    def self.handle_http_errors(response)
      if response.status == 404
        errmsg = "Resource not found: '#{response.url}'"
        errmsg << extract_error_summary(response.body)
        # ActiveSupport::SafeBuffer.new is the same as errmsg.html_safe in rails
        raise HttpNotFoundError.new(ActiveSupport::SafeBuffer.new(errmsg), response.status)
      elsif response.status >= 400
        errmsg = "Service request to '#{response.url}' failed (#{response.status}):"
        errmsg << extract_error_summary(response.body)
        raise HttpError.new(ActiveSupport::SafeBuffer.new(errmsg), response.status, response)
      end
      response
    end

    def self.with_curl(&block)
      easy = Thread.current[:pebblebed_curb_easy] ||= Curl::Easy.new
      easy.reset
      yield easy
      return handle_http_errors(Response.new(easy))
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
