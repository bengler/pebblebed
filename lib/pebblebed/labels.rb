module Pebblebed
  class Labels

    NO_MARKER = Class.new

    attr_reader :path, :prefix, :suffix, :stop
    def initialize(path, options = {})
      @path = path
      @prefix = options.fetch(:prefix) { 'label' }
      @suffix = options.fetch(:suffix) { nil }
      @stop = options.fetch(:stop) { NO_MARKER }
    end

    def next
      label(expanded.length)
    end

    def expanded
      unless @expanded
        values = {}
        path.split('.').each_with_index do |label, i|
          values[label(i)] = label
        end
        if use_stop_marker?
          values[label(values.length)] = stop
        end
        @expanded = values
      end
      @expanded
    end

    def label(i)
      [prefix, i, suffix].compact.join('_')
    end

    def use_stop_marker?
      stop != NO_MARKER
    end
  end

end
