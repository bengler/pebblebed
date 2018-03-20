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

  class HttpNotFoundError < HttpError; end

  module Http

    DEFAULT_CONNECT_TIMEOUT = 30
    DEFAULT_REQUEST_TIMEOUT = nil
    DEFAULT_READ_TIMEOUT = 30

    class << self
      attr_reader :connect_timeout, :request_timeout, :read_timeout
      def connect_timeout=(value)
        @connect_timeout = value
        self.current_easy = nil
      end
      def request_timeout=(value)
        @request_timeout = value
        self.current_easy = nil
      end
      def read_timeout=(value)
        @read_timeout = value
        self.current_easy = nil
      end
    end

    class Response
      def initialize(url, header, body)
        @body = body
        # We parse it ourselves because Curl::Easy fails when there's no text message
        @status = header.scan(/HTTP\/\d\.\d\s(\d+)\s/).map(&:first).last.to_i
        @url = url
      end

      attr_reader :body, :status, :url
    end

    def self.get(url = nil, params = nil, &block)
      url, params = url_and_params_from_args(url, params, &block)
      get_url = url_with_params(url, params)
      LOGGER.info("PebbleBedLog.get get_url: #{get_url}")
      result = do_easy { |easy|
        easy.url = get_url
        easy.http_get
      }
      LOGGER.info("PebbleBedLog.get result: #{result.inspect}")
      return result
    end

    def self.post(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      content_type, body = serialize_params(params)
      return do_easy { |easy|
        easy.url = url.to_s
        easy.headers['Accept'] = 'application/json'
        easy.headers['Content-Type'] = content_type
        easy.http_post(body)
      }
    end

    def self.put(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      content_type, body = serialize_params(params)
      return do_easy { |easy|
        easy.url = url.to_s
        easy.headers['Accept'] = 'application/json'
        easy.headers['Content-Type'] = content_type
        easy.http_put(body)
      }
    end

    def self.delete(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      return do_easy { |easy|
        easy.url = url_with_params(url, params)
        easy.http_delete
      }
    end

    def self.stream_get(url = nil, params = nil, options = {})
      return do_easy(cache: false) { |easy|
        on_data = options[:on_data] or raise "Option :on_data must be specified"

        url, params = url_and_params_from_args(url, params)

        easy.url = url_with_params(url, params)
        easy.on_body do |data|
          on_data.call(data)
          data.length
        end
        easy.http_get
      }
    end

    def self.stream_post(url, params, options = {})
      return do_easy(cache: false) { |easy|
        on_data = options[:on_data] or raise "Option :on_data must be specified"

        url, params = url_and_params_from_args(url, params)
        content_type, body = serialize_params(params)

        easy.url = url.to_s
        easy.headers['Accept'] = 'application/json'
        easy.headers['Content-Type'] = content_type
        easy.on_body do |data|
          on_data.call(data)
          data.length
        end
        easy.http_post(body)
      }
    end

    def self.stream_put(url, params, options = {})
      return do_easy(cache: false) { |easy|
        on_data = options[:on_data] or raise "Option :on_data must be specified"

        url, params = url_and_params_from_args(url, params)
        content_type, body = serialize_params(params)

        easy.url = url.to_s
        easy.headers['Accept'] = 'application/json'
        easy.headers['Content-Type'] = content_type
        easy.on_body do |data|
          on_data.call(data)
          data.length
        end
        easy.http_put(body)
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
        if (summary = extract_error_summary(response.body))
          errmsg << ": #{summary}"
        end
        # ActiveSupport::SafeBuffer.new is the same as errmsg.html_safe in rails
        raise HttpNotFoundError.new(ActiveSupport::SafeBuffer.new(errmsg), response.status)
      end

      if response.status >= 400
        errmsg = "Service request to '#{response.url}' failed (#{response.status})"
        if (summary = extract_error_summary(response.body))
          errmsg << ": #{summary}"
        end
        raise HttpError.new(ActiveSupport::SafeBuffer.new(errmsg), response.status, response)
      end

      response
    end

    def self.do_easy(cache: true, &block)
      with_easy(cache: cache) do |easy|
        yield easy
        response = Response.new(easy.url, easy.header_str, easy.body_str)
        return handle_http_errors(response)
      end
    end

    def self.with_easy(cache: true, &block)
      if cache
        easy = self.current_easy ||= new_easy
      else
        easy = new_easy
      end
      yield easy
    end

    def self.current_easy
      Thread.current[:pebblebed_curb_easy]
    end

    def self.current_easy=(value)
      if (current = Thread.current[:pebblebed_curb_easy])
        # Reset old instance
        current.reset
      end
      Thread.current[:pebblebed_curb_easy] = value
    end

    # Returns new Easy instance from current configuration.
    def self.new_easy
      easy = Curl::Easy.new
      easy.connect_timeout = connect_timeout || DEFAULT_CONNECT_TIMEOUT
      easy.timeout = request_timeout || DEFAULT_REQUEST_TIMEOUT
      easy.low_speed_time = read_timeout || DEFAULT_READ_TIMEOUT
      easy.low_speed_limit = 1
      easy.follow_location = true
      easy
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
      return nil unless body

      # Hack to support Sinatra error pages
      summary = Nokogiri::HTML(body).css('#summary').text.gsub(/\s+/, ' ').strip
      return summary if summary.length > 0

      summary = body
      summary = summary[0, 500] + "..." if summary.length > 500
      summary
    end

  end
end
