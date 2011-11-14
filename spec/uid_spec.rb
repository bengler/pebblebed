require 'spec_helper'

describe Pebbles::Uid do
  it "parses a full uid correctly" do
    uid = Pebbles::Uid.new("klass:path#oid")
    uid.klass.should eq "klass"
    uid.path.should eq "path"
    uid.oid.should eq "oid"
    uid.to_s.should eq "klass:path#oid"
  end

  it "parses an uid with no oid correctly" do
    uid = Pebbles::Uid.new("klass:path")
    uid.klass.should eq "klass"
    uid.path.should eq "path"
    uid.oid.should be_nil
    uid.to_s.should eq "klass:path"
  end

  it "parses an uid with no path correctly" do
    uid = Pebbles::Uid.new("klass:#oid")
    uid.klass.should eq "klass"
    uid.path.should be_nil
    uid.oid.should eq "oid"
    uid.to_s.should eq "klass:#oid"
  end

  it "raises an exception when you try to create an invalid uid" do
    -> { Pebbles::Uid.new("!:#298") }.should raise_error Pebbles::InvalidUid
  end

  it "raises an exception when you modify an uid with an invalid value" do
    uid = Pebbles::Uid.new("klass:path#oid")
    -> { uid.klass = "!" }.should raise_error Pebbles::InvalidUid
    -> { uid.path = "..." }.should raise_error Pebbles::InvalidUid
    -> { uid.oid = "(/&%$" }.should raise_error Pebbles::InvalidUid
  end

  it "rejects invalid labels for klass and oid" do
    Pebbles::Uid.valid_klass?("abc123").should be_true
    Pebbles::Uid.valid_klass?("abc123!").should be_false
    Pebbles::Uid.valid_klass?("").should be_false
    Pebbles::Uid.valid_oid?("abc123").should be_true
    Pebbles::Uid.valid_oid?("abc123!").should be_false
    Pebbles::Uid.valid_oid?("abc 123").should be_false
    Pebbles::Uid.valid_oid?("").should be_false
  end

  it "rejects invalid paths" do
    Pebbles::Uid.valid_path?("abc123").should be_true
    Pebbles::Uid.valid_path?("abc.123").should be_true
    Pebbles::Uid.valid_path?("").should be_true
    Pebbles::Uid.valid_path?("abc!.").should be_false
    Pebbles::Uid.valid_path?(".").should be_false
    Pebbles::Uid.valid_path?("ab. 123").should be_false
  end

end