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
        /(?<klass>^[^:]+)\:(?<path>[^\$]*)?\$?(?<oid>.*$)?/ =~ string
        [klass, path, oid]
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
        value.split('.').each do |label|
          return false unless self.valid_label?(label)
        end
        true
      end

      def valid_oid?(value)
        !value.nil? && !value.include?('/')
      end
    end
  end
end
