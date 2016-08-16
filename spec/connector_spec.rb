require 'spec_helper'
require 'pebblebed/config'
require 'pebblebed/connector'
require 'pebblebed/clients/abstract_client'
require 'pebblebed/clients/generic_client'
require 'pebblebed/clients/quorum_client'

describe "Pebblebed::Connector" do
  it "can configure clients for any service" do
    connector = Pebblebed::Connector.new("session_key")
    client = connector['foobar']
    expect(client.class.name).to eq "Pebblebed::GenericClient"
    expect(client.instance_variable_get(:@session_key)).to eq "session_key"
    expect(client.instance_variable_get(:@root_url).to_s).to match(/api\/foobar/)
  end

  it "caches any given client" do
    connector = Pebblebed::Connector.new("session_key")
    expect(connector['foobar']).to eq connector['foobar']
  end

  it "has key getter and setter" do
    connector = Pebblebed::Connector.new("session_key")
    expect(connector.key).to eq("session_key")
    connector.key = "another_key"
    expect(connector.key).to eq("another_key")
  end

end
