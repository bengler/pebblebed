module Pebblebed
  class Labels

    attr_reader :path, :prefix, :suffix
    def initialize(path, options = {})
      @path = path
      @prefix = options.fetch(:prefix) { 'label' }
      @suffix = options.fetch(:suffix) { nil }
    end

    def expanded
      values = {}
      path.split('.').each_with_index do |label, i|
        values[label(i)] = label
      end
      values
    end

    def label(i)
      [prefix, i, suffix].compact.join('_')
    end

    def resolve(positions)
      positions = positions.split('.')
      positions = truncate_invalid(positions)
      (0...MAX_DEPTH).map do |i|
        positions[i]
      end
    end

    def truncate_invalid(positions)
      labels = []
      (0...MAX_DEPTH).each do |i|
        break if positions[i].nil?
        labels << positions[i]
      end
      labels
    end

    if false
    include Enumerable

    attr_reader :labels, :all
    def initialize(positions)
      @all = resolve positions
      @labels = all.compact
    end

    def each
      labels.each {|label| yield label}
    end

    def [](index)
      labels[index]
    end

    def []=(index, value)
      labels[index] = value
    end

    def to_s
      labels.join('.')
    end

    class << self

      def to_conditions(path)
        unless Pebblebed::Uid.valid_path?(path)
          raise ArgumentError.new("Wildcards terminate the path. Invalid path: #{path}")
        end

        labels = path.split('.')
        # In a Pebblebed::Uid::WildcardPath, anything after '^' is optional.
        optional_part = false

        labels.map! do |label|
          if label =~ /^\^/
            label.gsub!(/^\^/, '')
            optional_part = true
          end

          result = label.include?('|') ? label.split('|') : label
          result = [label, nil].flatten if optional_part
          result
        end

        result = {}
        (0...MAX_DEPTH).map do |index|
          break if labels[index] == '*'
          result[:"label_#{index}"] = labels[index]
          break if labels[index].nil?
        end
        result
      end

    end
    end
  end

end
