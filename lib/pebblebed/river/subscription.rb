module Pebblebed
  class River
    class Subscription

      attr_reader :events, :klasses, :paths
      def initialize(options = {})
        @events = querify(options[:event]).split('|')
        @paths = querify(options[:path]).split('|')
        @klasses = querify(options[:klass]).split('|')
      end

      def queries
        qx = []
        # If we add more than one more level,
        # it's probably time to go recursive.
        events.each do |event|
          klasses.each do |klass|
            paths.each do |pathspec|
              pathify(pathspec).each do |path|
                qx << [event, klass, path].join('._.')
              end
            end
          end
        end
        qx
      end

      def querify(query)
        (query || '#').gsub('**', '#')
      end

      def pathify(s)
        required, optional = s.split('^').map {|s| s.split('.')}
        required = Array(required.join('.'))
        optional ||= []
        (0..optional.length).map {|i| required + optional[0,i]}.map {|p| p.join('.')}
      end
    end
  end
end
