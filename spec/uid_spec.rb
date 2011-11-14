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

end