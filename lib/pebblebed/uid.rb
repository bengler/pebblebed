require 'cgi'

module Pebblebed
  class InvalidUid < StandardError; end
  class Uid
    def initialize(args)
      case args
        when String
          self.klass, self.path, self.oid = self.class.raw_parse(args)
        when Hash
          self.klass, self.path, self.oid = args[:klass], args[:path], args[:oid]
        else raise "Invalid argument"
      end
      raise InvalidUid, "Missing klass in uid" unless self.klass
      raise InvalidUid, "A valid uid must specify either path or oid" unless self.path || self.oid
    end

    attr_reader :klass, :path, :oid
    def klass=(value)
      return @klass = nil if value == '' || value.nil?
      raise InvalidUid, "Invalid klass '#{value}'" unless self.class.valid_klass?(value)
      @klass = value
    end
    def path=(value)
      return @path = nil if value == '' || value.nil?
      raise InvalidUid, "Invalid path '#{value}'" unless self.class.valid_path?(value)
      @path = (value.strip != "") ? value : nil
    end
    def oid=(value)
      return @oid = nil if value == '' || value.nil?
      raise InvalidUid, "Invalid oid '#{value}'" unless self.class.valid_oid?(value)
      @oid = (value.strip != "") ? value : nil
    end

    def realm
      self.path.split(".").first if self.path
    end

    def inspect
      "#<Pebblebed::Uid '#{to_s}'>"
    end

    def to_s
      "#{@klass}:#{@path}$#{@oid}".chomp("$")
    end
    alias_method :to_uid, :to_s

    def ==(other)
      self.to_uid == other.to_uid
    end

    def eql?(other)
      self == other
    end

    class << self
      def raw_parse(string)
        if string =~ /\A([^:]+)\:([^\$]*)?\$?(.+)?\Z/
          klass, path, oid = $1, $2, $3
          [klass, path, oid]
        end
      end

      def valid?(string)
        begin
          true if new(string)
        rescue InvalidUid
          false
        end
      end

      def parse(string)
        uid = new(string)
        [uid.klass, uid.path, uid.oid]
      end

      def valid_label?(value)
        !!(value =~ /^[a-zA-Z0-9_-]+$/)
      end

      def valid_klass?(value)
        return false if value =~ /^\.+$/
        return false if value == ""
        value.split('.').each do |label|
          return false unless self.valid_label?(label)
        end
        true
      end

      def valid_path?(value)
        # catches a stupid edge case in ruby where "..".split('.') == [] instead of ["", "", ""]
        return false if value =~ /^\.+$/

        return true if valid_wildcard_path?(value)

        value.split('.').all? { |s| valid_label?(s) }
      end

      def valid_oid?(value)
        !value.nil? && !value.include?('/')
      end

      def wildcard_path?(value)
        value =~ /[\*\|\^]/
      end

      def valid_wildcard_path?(value)
        wildcard_path?(value) && WildcardPath.valid?(value)
      end
    end

    module WildcardPath

      class << self
        def valid?(path)
          stars_are_solitary?(path) && pipes_are_interleaved?(path) && carets_are_leading?(path) && stars_are_terminating?(path)
        end

        # a.*.c is accepted
        # a.*b.c is not
        # A later rule ensures that * always falls at the end of a path
        def stars_are_solitary?(path)
          !path.split('.').any? {|s| s.match(/.+\*|\*.+/)}
        end

        # a.b|c.d is accepted
        # a.|b.c is not
        def pipes_are_interleaved?(path)
          !path.split('.').any? {|s| s.match(/^\||\|$/)}
        end

        # a.^b.c is accepted
        # a.b^c.d is not
        def carets_are_leading?(path)
          !path.split('.').any? {|s| s.match(/.+\^|\^$/) }
        end

        # a.b.* is accepted
        # *.b.c is not
        def stars_are_terminating?(path)
          path !~ /.*\*\.\w/
        end

      end
    end

  end

end
