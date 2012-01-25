require 'spec_helper'

describe Pebblebed::Uid do
  it "parses a full uid correctly" do
    uid = Pebblebed::Uid.new("klass:path$oid")
    uid.klass.should eq "klass"
    uid.path.should eq "path"
    uid.oid.should eq "oid"
    uid.to_s.should eq "klass:path$oid"
  end

  it "parses an uid with no oid correctly" do
    uid = Pebblebed::Uid.new("klass:path")
    uid.klass.should eq "klass"
    uid.path.should eq "path"
    uid.oid.should be_nil
    uid.to_s.should eq "klass:path"
  end

  it "parses an uid with no path correctly" do
    uid = Pebblebed::Uid.new("klass:$oid")
    uid.klass.should eq "klass"
    uid.path.should be_nil
    uid.oid.should eq "oid"
    uid.to_s.should eq "klass:$oid"
  end

  it "can be created with a string" do
    uid = Pebblebed::Uid.new "klass:some.path$oid"
    uid.to_s.should eq "klass:some.path$oid"
  end

  it "can be created using parameters" do
    uid = Pebblebed::Uid.new :klass => 'klass', :path => 'some.path', :oid => 'oid'
    uid.to_s.should eq "klass:some.path$oid"
  end

  it "raises an error if parameter is neither string or hash" do
    lambda {Pebblebed::Uid.new([])}.should raise_exception
  end

  it "raises an exception when you try to create an invalid uid" do
    -> { Pebblebed::Uid.new("!:$298") }.should raise_error Pebblebed::InvalidUid
  end

  it "raises an exception when you modify a uid with an invalid value" do
    uid = Pebblebed::Uid.new("klass:path$oid")
    -> { uid.klass = "!" }.should raise_error Pebblebed::InvalidUid
    -> { uid.path = "..." }.should raise_error Pebblebed::InvalidUid
    -> { uid.oid = "/" }.should raise_error Pebblebed::InvalidUid
  end

  describe "oid" do
    it "is valid with pretty much anything" do
      Pebblebed::Uid.valid_oid?("abc123").should be_true
      Pebblebed::Uid.valid_oid?("abc123!").should be_true
      Pebblebed::Uid.valid_oid?("abc 123").should be_true
    end

    it "cannot contain a slash" do
      Pebblebed::Uid.valid_oid?("abc/123").should be_false
    end

    it "can contain a full uid" do
      Pebblebed::Uid.new('klass:path$post:some.path$oid').oid.should eq('post:some.path$oid')
    end

    it "can be missing" do
      Pebblebed::Uid.new('klass:path').oid.should be_nil
    end

    it "is not valid if it is nil" do
      Pebblebed::Uid.valid_oid?(nil).should be_false
    end
  end

  it "rejects invalid labels for klass" do
    Pebblebed::Uid.valid_klass?("abc123").should be_true
    Pebblebed::Uid.valid_klass?("abc123!").should be_false
    Pebblebed::Uid.valid_klass?("").should be_false
  end

  describe "path" do
    it "accepts valid paths" do
      Pebblebed::Uid.valid_path?("").should be_true
      Pebblebed::Uid.valid_path?("abc123").should be_true
      Pebblebed::Uid.valid_path?("abc.123").should be_true
      Pebblebed::Uid.valid_path?("abc.de-f.123").should be_true
    end

    it "rejects invalid paths" do
      Pebblebed::Uid.valid_path?("abc!.").should be_false
      Pebblebed::Uid.valid_path?(".").should be_false
      Pebblebed::Uid.valid_path?("ab. 123").should be_false
    end
  end

  it "knows how to parse in place" do
    Pebblebed::Uid.parse("klass:path$oid").should eq ['klass', 'path', 'oid']
    Pebblebed::Uid.parse("post:this.is.a.path.to$object_id").should eq ['post', 'this.is.a.path.to', 'object_id']
    Pebblebed::Uid.parse("post:$object_id").should eq ['post', nil, 'object_id']
  end

  it "knows the valid uids from the invalid ones" do
    Pebblebed::Uid.valid?("F**ing H%$#!!!").should be_false
    Pebblebed::Uid.valid?("").should be_false
    Pebblebed::Uid.valid?("bang:").should be_false
    Pebblebed::Uid.valid?(":bang").should be_false
    Pebblebed::Uid.valid?(":bang$paff").should be_false
    Pebblebed::Uid.valid?("$paff").should be_false
    Pebblebed::Uid.valid?("a:b.c.d$e").should be_true
    Pebblebed::Uid.valid?("a:$e").should be_true
    Pebblebed::Uid.valid?("a:b.c.d").should be_true
  end

  it "knows how to extract the realm from the path" do
    Pebblebed::Uid.new("klass:realm.other.stuff$3").realm.should eq 'realm'
    Pebblebed::Uid.new("klass:realm$3").realm.should eq 'realm'
    Pebblebed::Uid.new("klass:realm").realm.should eq 'realm'
    Pebblebed::Uid.new("klass:$3").realm.should eq nil
  end

  it "knows how to extract the realm from the path" do
    Pebblebed::Uid.new("klass:realm.other.stuff$3").realm.should eq 'realm'
    Pebblebed::Uid.new("klass:realm$3").realm.should eq 'realm'
    Pebblebed::Uid.new("klass:realm").realm.should eq 'realm'
    Pebblebed::Uid.new("klass:$3").realm.should eq nil
  end
end
