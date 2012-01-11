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

    def self.raw_parse(string)
      /(?<klass>^[^:]+)\:(?<path>[^\$]*)?\$?(?<oid>.*$)?/ =~ string
      [klass, path, oid]
    end

    def self.valid?(string)
      begin 
        true if new(string)
      rescue InvalidUid
        false
      end
    end

    def self.parse(string)
      uid = new(string)
      [uid.klass, uid.path, uid.oid]
    end

    def self.valid_label?(value)
      !!(value =~ /^[a-zA-Z0-9_]+$/)
    end

    def self.valid_klass?(value)
      self.valid_label?(value)
    end

    def self.valid_path?(value)
      # catches a stupid edge case in ruby where "..".split('.') == [] instead of ["", "", ""]
      return false if value =~ /^\.+$/ 
      value.split('.').each do |label|
        return false unless self.valid_label?(label)
      end
      true
    end

    def self.valid_oid?(value)
      !value.nil? && !value.include?('/')
    end

    def inspect
      "#<Pebblebed::Uid '#{to_s}'>"
    end

    def to_s
      "#{@klass}:#{@path}$#{@oid}".chomp("$")
    end
    alias_method :to_uid, :to_s 

  end
end
