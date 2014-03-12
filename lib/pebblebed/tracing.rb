module Pebblebed
  class Tracing

    VALID_ID_PATTERN = /\A[a-z0-9_:+\/.-]+\z/i.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      id = env['HTTP_PEBBLEBED_TRACE']
      if id
        # Some simple checks to discard malicious content
        id = id.to_s
        if id.length > 100 or id !~ VALID_ID_PATTERN
          if (logger = env['rack.errors'])
            logger.warn("'Pebblebed-Trace' header is invalid, discarding it")
          end
          id = nil
        end
      end
      Tracing.with(id) do |new_id|
        status, headers, body = @app.call(env)
        headers ||= {}
        headers['Pebblebed-Trace'] = new_id
        [status, headers, body]
      end
    end

    def self.current_id
      Thread.current[:pebblebed_trace_id]
    end

    def self.current_id!
      Thread.current[:pebblebed_trace_id] ||= generate_id
    end

    def self.current_id=(id)
      Thread.current[:pebblebed_trace_id] = id
    end

    def self.with(id = nil, &block)
      previous = Thread.current[:pebblebed_trace_id]
      id = Thread.current[:pebblebed_trace_id] = id || generate_id
      begin
        return yield id
      ensure
        Thread.current[:pebblebed_trace_id] = previous
      end
    end

    private

      def self.generate_id
        [
          Time.now.strftime('%Y%m%d%H%M%S'),
          Process.pid,
          zero_pad(Random.rand(0x19a0ff).to_s(36), 4)
        ].join('-').freeze
      end

      def self.zero_pad(s, length)
        if s.length < length
          ('0' * (length - s.length)) + s
        else
          s
        end
      end

  end
end
