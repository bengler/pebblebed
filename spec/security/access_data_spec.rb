require 'spec_helper'
require 'pebblebed/uid'
require 'pebblebed/security/access_data'

describe Pebblebed::Security::AccessData do
  let :access_data do
    Pebblebed::Security::AccessData.new(
      :access_groups => [1,2,3],
      :subtrees => ['a.b', 'a.b.c.d.e', 'a.c.d', 'a.c.e.f']
    )
  end

  it "can calculate a pristine path" do
    expect(Pebblebed::Security::AccessData.pristine_path("a.b.c|d")).to eq "a.b"
    expect(Pebblebed::Security::AccessData.pristine_path("a.b")).to eq "a.b"
  end

  it "can calculate relevant paths" do
    expect(access_data.relevant_subtrees('a.b').sort).to eq ['a.b', 'a.b.c.d.e']
    expect(access_data.relevant_subtrees('a.b.c').sort).to eq ['a.b', 'a.b.c.d.e']
    expect(access_data.relevant_subtrees('a.c.e').sort).to eq ['a.c.e.f']
    expect(access_data.relevant_subtrees('a.*').sort).to eq ['a.b', 'a.b.c.d.e', 'a.c.d', 'a.c.e.f']
  end

  it "can parse a checkpoint record" do
    record = {
      'memberships' => [
        {'membership' => {'id' => 10, 'group_id' => 1, 'identity_id' => 1}},
        {'membership' => {'id' => 20, 'group_id' => 2, 'identity_id' => 1}},
      ],
      'access_groups' => [
        {'access_group' => {'id' => 1, 'label' => "group_1", 'subtrees' => ["a.b.c"]}},
        {'access_group' => {'id' => 2, 'label' => "group_2", 'subtrees' => ["a.c.d.c"]}}
      ]
    }
    ad = Pebblebed::Security::AccessData.new(record)
    expect(ad.subtrees.sort).to eq ['a.b.c', 'a.c.d.c']
    expect(ad.group_ids.sort).to eq [1,2]
  end
end
