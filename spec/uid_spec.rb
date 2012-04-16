require 'spec_helper'

describe Pebblebed::Uid do
  describe "parsing" do
    context "a full uid" do
      subject { Pebblebed::Uid.new("klass:path$oid") }

      its(:klass) { should eq "klass" }
      its(:path) { should eq "path" }
      its(:oid) { should eq "oid" }
      its(:to_s) { should eq "klass:path$oid" }
    end

    context "without oid" do
      subject { Pebblebed::Uid.new("klass:path") }

      its(:klass) { should eq "klass" }
      its(:path) { should eq "path" }
      its(:oid) { should be_nil }
      its(:to_s) { should eq "klass:path" }
    end

    context "without path" do
      subject { Pebblebed::Uid.new("klass:$oid") }

      its(:klass) { should eq "klass" }
      its(:path) { should be_nil }
      its(:oid) { should eq "oid" }
      its(:to_s) { should eq "klass:$oid" }
    end
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

  describe "raises an exception when you modify a uid with an invalid value" do
    let(:uid) { Pebblebed::Uid.new("klass:path$oid") }
    specify { -> { uid.klass = "!" }.should raise_error Pebblebed::InvalidUid }
    specify { -> { uid.path = "..." }.should raise_error Pebblebed::InvalidUid }
    specify { -> { uid.oid = "/" }.should raise_error Pebblebed::InvalidUid }
  end

  describe "klass" do
    let(:uid) { Pebblebed::Uid.new("klass:path$oid") }

    it "allows sub-klasses" do
      ->{ uid.klass = "sub.sub.class" }.should_not raise_error
    end

    describe "is valid" do
      %w(. - _ 8).each do |nice_character|
        it "with '#{nice_character}'" do
          ->{ uid.klass = "a#{nice_character}z" }.should_not raise_error
        end
      end
    end

    describe "is invalid" do
      %w(! / : $ % $).each do |funky_character|
        specify "with '#{funky_character}'" do
          ->{ uid.klass = "a#{funky_character}z" }.should raise_error Pebblebed::InvalidUid
        end
      end
    end
  end

  describe "oid" do
    [
      "abc123",
      "abc123!@\#$%^&*()[]{}",
      "abc 123",
      "alice@example.com",
      "abc/123",
      "post:some.path$oid",
    ].each do |oid|
      specify "'#{oid}' is a valid oid if GCI escaped" do
        Pebblebed::Uid.valid_oid?(CGI.escape(oid)).should be_true
      end
    end

    specify "'abc/123' is an invalid oid" do
      Pebblebed::Uid.valid_oid?('abc/123').should be_false
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

  describe "validating paths" do
    specify { Pebblebed::Uid.valid_path?("").should be_true }
    specify { Pebblebed::Uid.valid_path?("abc123").should be_true }
    specify { Pebblebed::Uid.valid_path?("abc.123").should be_true }
    specify { Pebblebed::Uid.valid_path?("abc.de-f.123").should be_true }

    specify { Pebblebed::Uid.valid_path?("abc!.").should be_false }
    specify { Pebblebed::Uid.valid_path?(".").should be_false }
    specify { Pebblebed::Uid.valid_path?("ab. 123").should be_false }
  end

  describe "parsing in place" do
    specify { Pebblebed::Uid.parse("klass:path$oid").should eq ['klass', 'path', 'oid'] }
    specify { Pebblebed::Uid.parse("post:this.is.a.path.to$object_id").should eq ['post', 'this.is.a.path.to', 'object_id'] }
    specify { Pebblebed::Uid.parse("post:$object_id").should eq ['post', nil, 'object_id'] }
  end

  describe "validating uids" do
    specify { Pebblebed::Uid.valid?("a:b.c.d$e").should be_true }
    specify { Pebblebed::Uid.valid?("a:$e").should be_true }
    specify { Pebblebed::Uid.valid?("a:b.c.d").should be_true }
    specify { Pebblebed::Uid.valid?("F**ing H%$#!!!").should be_false }
    specify { Pebblebed::Uid.valid?("").should be_false }
    specify { Pebblebed::Uid.valid?("bang:").should be_false }
    specify { Pebblebed::Uid.valid?(":bang").should be_false }
    specify { Pebblebed::Uid.valid?(":bang$paff").should be_false }
    specify { Pebblebed::Uid.valid?("$paff").should be_false }
  end

  describe "extracting realm from path" do
    specify { Pebblebed::Uid.new("klass:realm.other.stuff$3").realm.should eq 'realm' }
    specify { Pebblebed::Uid.new("klass:realm$3").realm.should eq 'realm' }
    specify { Pebblebed::Uid.new("klass:realm").realm.should eq 'realm' }
    specify { Pebblebed::Uid.new("klass:$3").realm.should eq nil }
  end

  describe "equality" do
    let(:uid) { "klass:realm$3" }
    it "is dependent on the actual uid" do
      Pebblebed::Uid.new("klass:realm$3").should eq Pebblebed::Uid.new("klass:realm$3")
    end

    it "also works for eql?" do
      Pebblebed::Uid.new("klass:realm$3").eql?(Pebblebed::Uid.new("klass:realm$3")).should be_true
    end
  end
end
