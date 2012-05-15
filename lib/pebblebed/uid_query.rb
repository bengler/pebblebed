module Pebblebed
  class UIDQuery

    attr_reader :uids, :path, :oid
    def initialize(uids)
      @multiple = uids =~ /\,/
      if list?
        @uids = uids.split(',')
      else
        @klass, @path, @oid = Uid.parse(uids)
        @uids = uids
      end
    end

    def list?
      !!@multiple
    end

    def one?
      !(list? || wildcard?)
    end

    def wildcard?
      Uid.valid_wildcard_path?(path) || wildcard_oid?
    end

    def wildcard_oid?
      !list? && (oid == '*' || oid.nil?)
    end
  end
end
