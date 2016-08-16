require 'spec_helper'
require 'pebblebed/uid'

describe Pebblebed::Uid do
  describe "parsing" do
    context "a full uid" do
      subject { Pebblebed::Uid.new("klass:path$oid") }

      describe '#klass' do
        subject { super().klass }
        it { is_expected.to eq "klass" }
      end

      describe '#path' do
        subject { super().path }
        it { is_expected.to eq "path" }
      end

      describe '#oid' do
        subject { super().oid }
        it { is_expected.to eq "oid" }
      end

      describe '#to_s' do
        subject { super().to_s }
        it { is_expected.to eq "klass:path$oid" }
      end
    end

    context "without oid" do
      subject { Pebblebed::Uid.new("klass:path") }

      describe '#klass' do
        subject { super().klass }
        it { is_expected.to eq "klass" }
      end

      describe '#path' do
        subject { super().path }
        it { is_expected.to eq "path" }
      end

      describe '#oid' do
        subject { super().oid }
        it { is_expected.to be_nil }
      end

      describe '#to_s' do
        subject { super().to_s }
        it { is_expected.to eq "klass:path" }
      end
    end

    context "without path" do
      subject { Pebblebed::Uid.new("klass:$oid") }

      describe '#klass' do
        subject { super().klass }
        it { is_expected.to eq "klass" }
      end

      describe '#path' do
        subject { super().path }
        it { is_expected.to be_nil }
      end

      describe '#oid' do
        subject { super().oid }
        it { is_expected.to eq "oid" }
      end

      describe '#to_s' do
        subject { super().to_s }
        it { is_expected.to eq "klass:$oid" }
      end
    end
  end

  it "can be created with a string" do
    uid = Pebblebed::Uid.new "klass:some.path$oid"
    expect(uid.to_s).to eq "klass:some.path$oid"
  end

  it "can be created using parameters" do
    uid = Pebblebed::Uid.new :klass => 'klass', :path => 'some.path', :oid => 'oid'
    expect(uid.to_s).to eq "klass:some.path$oid"
  end

  it "raises an error if parameter is neither string or hash" do
    expect {Pebblebed::Uid.new([])}.to raise_exception
  end

  it "raises an exception when you try to create an invalid uid" do
    expect { Pebblebed::Uid.new("!:$298") }.to raise_error Pebblebed::InvalidUid
  end

  describe "raises an exception when you modify a uid with an invalid value" do
    let(:uid) { Pebblebed::Uid.new("klass:path$oid") }
    specify { expect { uid.klass = "!" }.to raise_error Pebblebed::InvalidUid }
    specify { expect { uid.path = "..." }.to raise_error Pebblebed::InvalidUid }
    specify { expect { uid.oid = "/" }.to raise_error Pebblebed::InvalidUid }
  end

  describe "klass" do
    let(:uid) { Pebblebed::Uid.new("klass:path$oid") }

    it "allows sub-klasses" do
      expect{ uid.klass = "sub.sub.class" }.not_to raise_error
    end

    describe "is valid" do
      %w(. - _ 8).each do |nice_character|
        it "with '#{nice_character}'" do
          expect{ uid.klass = "a#{nice_character}z" }.not_to raise_error
        end
      end
    end

    describe "is invalid" do
      %w(! / : $ % $).each do |funky_character|
        specify "with '#{funky_character}'" do
          expect{ uid.klass = "a#{funky_character}z" }.to raise_error Pebblebed::InvalidUid
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
        expect(Pebblebed::Uid.valid_oid?(CGI.escape(oid))).to be_truthy
      end
    end

    specify "'abc/123' is an invalid oid" do
      expect(Pebblebed::Uid.valid_oid?('abc/123')).to be_falsey
    end

    it "can be missing" do
      expect(Pebblebed::Uid.new('klass:path').oid).to be_nil
    end

    it "is not valid if it is nil" do
      expect(Pebblebed::Uid.valid_oid?(nil)).to be_falsey
    end
  end

  it "rejects invalid labels for klass" do
    expect(Pebblebed::Uid.valid_klass?("abc123")).to be_truthy
    expect(Pebblebed::Uid.valid_klass?("abc123!")).to be_falsey
    expect(Pebblebed::Uid.valid_klass?("")).to be_falsey
  end

  describe "validating paths" do
    specify { expect(Pebblebed::Uid.valid_path?("")).to be_truthy }
    specify { expect(Pebblebed::Uid.valid_path?("abc123")).to be_truthy }
    specify { expect(Pebblebed::Uid.valid_path?("abc.123")).to be_truthy }
    specify { expect(Pebblebed::Uid.valid_path?("abc.de-f.123")).to be_truthy }

    specify { expect(Pebblebed::Uid.valid_path?("abc!.")).to be_falsey }
    specify { expect(Pebblebed::Uid.valid_path?(".")).to be_falsey }
    specify { expect(Pebblebed::Uid.valid_path?("ab. 123")).to be_falsey }

    context "with wildcards" do
      specify { expect(Pebblebed::Uid.valid_path?('*')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('a.b.c.*')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('a.b|c.d')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('a.b|c.*')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('^a')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('^a.b')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('^a.b.c')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('a.^b.c')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('a.^b.c|d.e')).to be_truthy }
      specify { expect(Pebblebed::Uid.valid_path?('a.^b.c.*')).to be_truthy }

      specify { expect(Pebblebed::Uid.valid_path?('*a')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('a*')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('*.b')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('a.*.b')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('|')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('a.|b')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('a.b|')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('a.|b.c')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('a.b|.c')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('^')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('^.a')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('a^')).to be_falsey }
      specify { expect(Pebblebed::Uid.valid_path?('a^b.c')).to be_falsey }
    end
  end

  describe "wildcard paths" do
    specify { expect(Pebblebed::Uid.wildcard_path?('*')).to be_truthy }
    specify { expect(Pebblebed::Uid.wildcard_path?('a.b|c.d')).to be_truthy }
    specify { expect(Pebblebed::Uid.wildcard_path?('a.^b.d')).to be_truthy }
    specify { expect(Pebblebed::Uid.wildcard_path?('a.b.d')).to be_falsey }
  end

  describe "parsing in place" do
    specify { expect(Pebblebed::Uid.parse("klass:path$oid")).to eq ['klass', 'path', 'oid'] }
    specify { expect(Pebblebed::Uid.parse("post:this.is.a.path.to$object_id")).to eq ['post', 'this.is.a.path.to', 'object_id'] }
    specify { expect(Pebblebed::Uid.parse("post:$object_id")).to eq ['post', nil, 'object_id'] }
  end

  describe "validating uids" do
    specify { expect(Pebblebed::Uid.valid?("a:b.c.d$e")).to be_truthy }
    specify { expect(Pebblebed::Uid.valid?("a:$e")).to be_truthy }
    specify { expect(Pebblebed::Uid.valid?("a:b.c.d")).to be_truthy }
    specify { expect(Pebblebed::Uid.valid?("F**ing H%$#!!!")).to be_falsey }
    specify { expect(Pebblebed::Uid.valid?("")).to be_falsey }
    specify { expect(Pebblebed::Uid.valid?("bang:")).to be_falsey }
    specify { expect(Pebblebed::Uid.valid?(":bang")).to be_falsey }
    specify { expect(Pebblebed::Uid.valid?(":bang$paff")).to be_falsey }
    specify { expect(Pebblebed::Uid.valid?("$paff")).to be_falsey }
  end

  describe "extracting realm from path" do
    specify { expect(Pebblebed::Uid.new("klass:realm.other.stuff$3").realm).to eq 'realm' }
    specify { expect(Pebblebed::Uid.new("klass:realm$3").realm).to eq 'realm' }
    specify { expect(Pebblebed::Uid.new("klass:realm").realm).to eq 'realm' }
    specify { expect(Pebblebed::Uid.new("klass:$3").realm).to eq nil }
  end

  describe "equality" do
    let(:uid) { "klass:realm$3" }
    it "is dependent on the actual uid" do
      expect(Pebblebed::Uid.new("klass:realm$3")).to eq Pebblebed::Uid.new("klass:realm$3")
    end

    it "also works for eql?" do
      expect(Pebblebed::Uid.new("klass:realm$3").eql?(Pebblebed::Uid.new("klass:realm$3"))).to be_truthy
    end
  end
end
