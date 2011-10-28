require 'rack/streaming_proxy'

module Pebblebed
  class PowProxy < Rack::StreamingProxy
    def initialize(app, &block)
      super(app) do |request|
        result = yield(request) if block_given?
        result ||= self.class.remap(request)
      end
    end

    class << self
      def remap(request)
        service, path = remap_path(request.env['PATH_INFO'])
        "http://#{service}.dev/api#{path}?#{request.env['QUERY_STRING']}".chomp('?') if service
      end

      def remap_path(original_path)
        /^\/api\/(?<service>[^\/]+)(?<path>\/.+)?$/ =~ original_path
        [service, path] if api_path?(path)
      end

      def api_path?(path)
        path =~ /^\/v\d+/
      end
    end
  end
end
