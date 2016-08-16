require 'spec_helper'
require 'pebblebed/config'
require 'pebblebed/connector'
require 'pebblebed/clients/abstract_client'
require 'pebblebed/clients/generic_client'
require 'pebblebed/clients/quorum_client'

describe "Pebblebed::Connector" do

  Pebblebed.config do
    service :foobar
  end

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

  context 'scheme' do

    Pebblebed.config do
      service :barbaz
    end

    it 'works for http' do
      connector_options = {
        :host => 'example.org',
        :scheme => 'http'
      }
      connector = ::Pebblebed::Connector.new('session_key', connector_options)
      client = connector['barbaz']
      expect(client.instance_variable_get(:@root_url).to_s).to eq 'http://example.org/api/barbaz/v1/'
    end

    it 'works for https' do
      connector_options = {
        :host => 'example.org',
        :scheme => 'https'
      }
      connector = ::Pebblebed::Connector.new('session_key', connector_options)
      client = connector['barbaz']
      expect(client.instance_variable_get(:@root_url).to_s).to eq 'https://example.org/api/barbaz/v1/'
    end

  end

end
