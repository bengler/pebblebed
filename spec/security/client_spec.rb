require 'spec_helper'
require 'pebblebed/uid'
require 'pebblebed/security/access_data'
require 'pebblebed/security/client'

describe Pebblebed::Security::Client do
  let :client do
    Pebblebed::Security::Client.new(nil)
  end

  let :sample_memberships_record do
    {
      'memberships' => [
        {'membership' => {'id' => 10, 'group_id' => 1, 'identity_id' => 1}},
        {'membership' => {'id' => 20, 'group_id' => 2, 'identity_id' => 1}},
      ],
      'groups' => [
        {'group' => {'id' => 1, 'label' => "group_1", 'subtrees' => ["a.b.c"]}},
        {'group' => {'id' => 2, 'label' => "group_2", 'subtrees' => ["a.c.d.c"]}}
      ]
    }
  end

  it "can fetch access_data" do
    client.stub(:fetch_membership_data_for).and_return(sample_memberships_record)
    ad = client.access_data_for(1)
    ad.subtrees.sort.should eq ['a.b.c', 'a.c.d.c']
  end
end
