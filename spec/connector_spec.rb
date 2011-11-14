require 'spec_helper'

describe "Pebbles::Connector" do
  it "can configure clients for any service" do
    connector = Pebbles::Connector.new("session_key")
    client = connector['foobar']
    client.class.name.should eq "Pebbles::GenericClient"
    client.instance_variable_get(:@session_key).should eq "session_key"
    client.instance_variable_get(:@root_url).to_s.should =~ /api\/foobar/
  end

  it "caches any given client" do
    connector = Pebbles::Connector.new("session_key")
    connector['foobar'].should eq connector['foobar']
  end

  it "fetches specific client implementations if one is provided" do
    connector = Pebbles::Connector.new("session_key")
    connector['checkpoint'].class.name.should eq "Pebbles::CheckpointClient"
    connector['foobar'].class.name.should eq "Pebbles::GenericClient"
  end

end