require 'rack/streaming_proxy'

module Pebbles
  class PowProxy < Rack::StreamingProxy
    def initialize(app, &block)
      super(app) do |request|
        result = yield(request) if block_given?
        result ||= self.class.remap(request)
      end
    end

    class << self
      def remap(request)
        service = extract_service_name(request.env['PATH_INFO'])
        "http://#{service}.dev#{request.env['PATH_INFO']}?#{request.env['QUERY_STRING']}".chomp('?') if service
      end

      def extract_service_name(original_path)
        original_path.scan(/^\/api\/([^\/]+)\/v\d+\//).flatten.first
      end
    end
  end
end
