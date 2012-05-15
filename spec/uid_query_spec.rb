require 'pebblebed/uid'
require 'pebblebed/uid_query'

describe Pebblebed::UIDSpec do
  context "with comma separated uids." do
    subject { Pebblebed::UIDSpec.new("xyz:a.b.c$1,xyz:a.b.c$2") }

    its(:list?) { should be_true }
    its(:wildcard?) { should be_false }
    its(:one?) { should be_false }
    its(:uids) { should eq(["xyz:a.b.c$1", "xyz:a.b.c$2"]) }

  end

  context "with a wildcard path." do
    subject { Pebblebed::UIDSpec.new("xyz:a.b.*") }

    its(:list?) { should be_false }
    its(:wildcard?) { should be_true }
    its(:one?) { should be_false }
    its(:uids) { should eq("xyz:a.b.*") }
  end

  context "without any oid." do
    subject { Pebblebed::UIDSpec.new("xyz:a.b.c") }

    its(:list?) { should be_false }
    its(:wildcard?) { should be_true }
    its(:one?) { should be_false }
    its(:uids) { should eq("xyz:a.b.c") }
  end

  context "with a wildcard oid." do
    subject { Pebblebed::UIDSpec.new("xyz:a.b.c$*") }

    its(:list?) { should be_false }
    its(:wildcard?) { should be_true }
    its(:one?) { should be_false }
    its(:uids) { should eq("xyz:a.b.c$*") }
  end

  context "with a completely constrained uid" do
    subject { Pebblebed::UIDSpec.new("xyz:a.b.c$1") }

    its(:list?) { should be_false }
    its(:wildcard?) { should be_false }
    its(:one?) { should be_true }
    its(:uids) { should eq("xyz:a.b.c$1") }
  end
end
