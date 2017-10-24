module Pebblebed

  # Helper class which buffers an NDJSON input stream, parsing each
  # complete line into a handler as JSON.
  class NdjsonBuffer

    # Initializes with handler. The handler must provide a method 'call'
    # which will be called with each JSON payload.
    def initialize(handler)
      @handler = handler
      @buf = ''
      @end = false
    end

    # Returns true if the end of the stream has been reached.
    def ended?
      @end
    end

    # Checks whether this buffer has reached its end. Raises IOError
    # otherwise.
    def check_end!
      unless @end
        # We need to raise this to signal that a complete contents
        # was not returned.
        raise IOError, "End of stream expected"
      end
    end

    # Feeds data into the buffer.
    def <<(data)
      return if data.empty?
      @buf << data
      begin
        if /\A(?<line>[^\n]*)\n(?<rest>.*)\z/m =~ @buf
          if line.length == 0 && rest.length == 0
            @buf.clear
            @end = true
          else
            payload, @buf = JSON.parse(line), rest
            @handler.call(payload)
          end
        else
          break
        end
      end until @end
    end

  end

end
