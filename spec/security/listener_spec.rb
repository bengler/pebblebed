require 'spec_helper'
require 'pebblebed/uid'
require 'pebblebed/security/listener'

describe Pebblebed::Security::Listener do
  let :listener do
    Pebblebed::Security::Listener.new(:app_name => "test")
  end

  it "can generate events from incoming messages" do
    the_attrs = nil
    listener.on_group_declared do |attrs|
      the_attrs = attrs
    end
    message = {:payload => {
      'event' => 'create',
      'uid' => 'access_group:abc.access_groups$10',
      'attributes' => {
        'id' => 10,
        'label' => 'the_label'
      }
    }.to_json}
    listener.send(:consider, message)
    expect(the_attrs[:id]).to eq 10
  end
end
