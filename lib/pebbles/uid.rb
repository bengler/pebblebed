module Pebbles
  class Uid
    def initialize(uid)
      /(?<klass>^[^:]+)\:(?<path>[^\#]*)?\#?(?<oid>.*$)?/ =~ uid
      self.klass, self.path, self.oid = klass, path, oid
    end

    attr_reader :klass, :path, :oid
    def klass=(value)
      @klass = (value.strip != "") ? value : nil
    end
    def path=(value)
      @path = (value.strip != "") ? value : nil
    end
    def oid=(value)
      @oid = (value.strip != "") ? value : nil
    end

    def to_s
      "#{@klass}:#{@path}##{@oid}".chomp("#")
    end
  end
end
