require 'spec_helper'

describe "Pebblebed::Connector" do
  it "can configure clients for any service" do
    connector = Pebblebed::Connector.new("session_key")
    client = connector['foobar']
    client.class.name.should eq "Pebblebed::GenericClient"
    client.instance_variable_get(:@session_key).should eq "session_key"
    client.instance_variable_get(:@root_url).to_s.should =~ /api\/foobar/
  end

  it "caches any given client" do
    connector = Pebblebed::Connector.new("session_key")
    connector['foobar'].should eq connector['foobar']
  end

  it "fetches specific client implementations if one is provided" do
    connector = Pebblebed::Connector.new("session_key")
    connector['checkpoint'].class.name.should eq "Pebblebed::CheckpointClient"
    connector['foobar'].class.name.should eq "Pebblebed::GenericClient"
  end

end