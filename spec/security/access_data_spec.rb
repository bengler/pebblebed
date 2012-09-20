require 'spec_helper'
require 'pebblebed/uid'
require 'pebblebed/security/access_data'

describe Pebblebed::Security::AccessData do
  let :access_data do
    Pebblebed::Security::AccessData.new(
      :groups => [1,2,3],
      :subtrees => ['a.b', 'a.b.c.d.e', 'a.c.d', 'a.c.e.f']
    )
  end

  it "can calculate a pristine path" do
    Pebblebed::Security::AccessData.pristine_path("a.b.c|d").should eq "a.b"
    Pebblebed::Security::AccessData.pristine_path("a.b").should eq "a.b"
  end

  it "can calculate relevant paths" do
    access_data.relevant_subtrees('a.b').sort.should eq ['a.b', 'a.b.c.d.e']
    access_data.relevant_subtrees('a.b.c').sort.should eq ['a.b', 'a.b.c.d.e']
    access_data.relevant_subtrees('a.c.e').sort.should eq ['a.c.e.f']
    access_data.relevant_subtrees('a.*').sort.should eq ['a.b', 'a.b.c.d.e', 'a.c.d', 'a.c.e.f']
  end

  it "can parse a checkpoint record" do
    record = {
      'memberships' => [
        {'membership' => {'id' => 10, 'group_id' => 1, 'identity_id' => 1}},
        {'membership' => {'id' => 20, 'group_id' => 2, 'identity_id' => 1}},
      ],
      'groups' => [
        {'group' => {'id' => 1, 'label' => "group_1", 'subtrees' => ["a.b.c"]}},
        {'group' => {'id' => 2, 'label' => "group_2", 'subtrees' => ["a.c.d.c"]}}
      ]
    }
    ad = Pebblebed::Security::AccessData.new(record)
    ad.subtrees.sort.should eq ['a.b.c', 'a.c.d.c']
    ad.group_ids.sort.should eq [1,2]
  end
end
