# A wrapper for all low level http client stuff

require 'uri'
require 'excon'
require 'yajl/json_gem'
require 'queryparams'
require 'nokogiri'
require 'pathbuilder'
require 'active_support'
require 'timeout'
require 'resolv'

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

  class HttpTransportError < StandardError
    def initialize(e = nil)
      super e
      set_backtrace e.backtrace if e
    end
  end

  class HttpNotFoundError < HttpError; end
  class HttpSocketError < HttpTransportError; end
  class HttpTimeoutError < HttpTransportError; end

  module Http

    DEFAULT_CONNECT_TIMEOUT = 30
    DEFAULT_READ_TIMEOUT = 30
    DEFAULT_WRITE_TIMEOUT = 60

    class << self
      attr_reader :connect_timeout, :read_timeout, :write_timeout
      def connect_timeout=(value)
        @connect_timeout = value
        Thread.current[:pebblebed_excon] = {}
      end
      def read_timeout=(value)
        @read_timeout = value
        Thread.current[:pebblebed_excon] = {}
      end
      def write_timeout=(value)
        @write_timeout = value
        Thread.current[:pebblebed_excon] = {}
      end
    end

    class Response
      def initialize(url, status, body)
        @body = body
        @status = status
        @url = url
      end

      attr_reader :body, :status, :url
    end

    def self.get(url = nil, params = nil, &block)
      url, params = url_and_params_from_args(url, params, &block)
      return do_request(url) { |connection|
        connection.get(
          :host => url.host,
          :path => url.path,
          :query => params,
          :persistent => true
        )
      }
    end

    def self.post(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      content_type, body = serialize_params(params)
      return do_request(url, idempotent: false) { |connection|
        connection.post(
          :host => url.host,
          :path => url.path,
          :headers => {
            'Accept' => 'application/json',
            'Content-Type' => content_type
          },
          :body => body,
          :persistent => true
        )
      }
    end

    def self.put(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      content_type, body = serialize_params(params)
      return do_request(url) { |connection|
        connection.put(
          :host => url.host,
          :path => url.path,
          :headers => {
            'Accept' => 'application/json',
            'Content-Type' => content_type
          },
          :body => body,
          :persistent => true
        )
      }
    end

    def self.delete(url, params, &block)
      url, params = url_and_params_from_args(url, params, &block)
      return do_request(url) { |connection|
        connection.delete(
          :host => url.host,
          :path => url.path,
          :query => params,
          :persistent => true
        )
      }
    end

    def self.streamer(on_data)
      lambda do |chunk, remaining_bytes, total_bytes|
        on_data.call(chunk)
        total_bytes
      end
    end

    def self.stream_get(url = nil, params = nil, options = {})
      on_data = options[:on_data] or raise "Option :on_data must be specified"

      url, params = url_and_params_from_args(url, params)
      return do_request(url) { |connection|
        connection.get(
          :host => url.host,
          :path => url.path,
          :query => params,
          :persistent => false,
          :response_block => streamer(on_data)
        )
      }
    end

    def self.stream_post(url, params, options = {})
      on_data = options[:on_data] or raise "Option :on_data must be specified"

      url, params = url_and_params_from_args(url, params)
      content_type, body = serialize_params(params)

      return do_request(url) { |connection|
        connection.post(
          :host => url.host,
          :path => url.path,
          :headers => {
            'Accept' => 'application/json',
            'Content-Type' => content_type
          },
          :body => body,
          :persistent => false,
          :response_block => streamer(on_data)
        )
      }
    end

    def self.stream_put(url, params, options = {})
      on_data = options[:on_data] or raise "Option :on_data must be specified"

      url, params = url_and_params_from_args(url, params)
      content_type, body = serialize_params(params)

      return do_request(url) { |connection|
        connection.put(
          :host => url.host,
          :path => url.path,
          :headers => {
            'Accept' => 'application/json',
            'Content-Type' => content_type
          },
          :body => body,
          :persistent => false,
          :response_block => streamer(on_data)
        )
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

    def self.do_request(url, idempotent: true, &block)
      with_connection(url) { |connection|
        begin
          request = block.call(connection)
          response = Response.new(url, request.status, request.body)
          return handle_http_errors(response)
        rescue Excon::Errors::Timeout => error
          raise HttpTimeoutError.new(error)
        rescue Excon::Errors::SocketError => error
          raise HttpSocketError.new(error) unless idempotent
          # Connection failed, close the connection and try again
          connection.reset
          begin
            request = block.call(connection)
            response = Response.new(url, request.status, request.body)
            return handle_http_errors(response)
          rescue Excon::Errors::SocketError => error
            raise HttpSocketError.new(error)
          end
        end
      }
    end

    def self.with_connection(url, &block)
      connection = self.current_connection(url) || new_connection(url)
      self.current_connection={:url => url, :connection => connection}
      yield connection
    end

    def self.base_url(url)
      if url.is_a?(URI)
        uri = url
      else
        uri = URI.parse(url)
      end
      "#{uri.scheme}://#{uri.host}:#{uri.port}"
    end

    def self.cache_key(url)
      if url.is_a?(URI)
        uri = url
      else
        uri = URI.parse(url)
      end
      ip = Resolv.getaddress(uri.host)
      "#{uri.scheme}://#{ip}:#{uri.port}"
    end

    def self.current_connection(url)
      Thread.current[:pebblebed_excon] ||= {}
      Thread.current[:pebblebed_excon][cache_key(url)]
    end

    def self.current_connection=(value)
      Thread.current[:pebblebed_excon] ||= {}
      Thread.current[:pebblebed_excon][cache_key(value[:url])] = value[:connection]
    end

    # Returns new Excon conection from current configuration.
    def self.new_connection(url)
      connection = Excon.new(base_url(url), {
        :read_timeout => read_timeout || DEFAULT_READ_TIMEOUT,
        :write_timeout => write_timeout || DEFAULT_WRITE_TIMEOUT,
        :connect_timeout => connect_timeout || DEFAULT_CONNECT_TIMEOUT,
        :thread_safe_sockets => false
      })
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
