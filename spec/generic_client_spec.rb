require 'spec_helper'
require 'pebblebed/config'
require 'pebblebed/clients/abstract_client'
require 'pebblebed/clients/generic_client'

module Pebblebed
  module Http
  end
end

describe Pebblebed::GenericClient do

  Pebblebed.config do
    memcached "MemcachedClient"
  end

  it "always forwards the session key" do
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    expect(client.service_params({})['session']).to eq "session_key"
  end

  it "always converts urls to URI-objects" do
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    expect(client.instance_variable_get(:@root_url).class.name).to eq ("URI::HTTP")
  end

  it "knows how to generate a service specific url" do
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    expect(client.service_url("/test").to_s).to eq "http://example.org/test"
    expect(client.service_url("").to_s).to eq "http://example.org"
    expect(client.service_url("/test", :foo => 'bar').to_s).to eq "http://example.org/test?foo=bar"
  end

  it "wraps JSON-results in a deep struct" do
    curl_result = DeepStruct.wrap({status:200, body:'{"hello":"world"}'})
    allow(Pebblebed::Http).to receive(:get).and_return(curl_result)
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    result = client.get "/"
    expect(result.class.name).to eq "DeepStruct::HashWrapper"
    expect(result.hello).to eq "world"
  end

  it "does not wrap non-json results" do
    curl_result = DeepStruct.wrap({status:200, body:'Ok'})
    allow(Pebblebed::Http).to receive(:get).and_return(curl_result)
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    result = client.get "/"
    expect(result.class.name).to eq "String"
    expect(result).to eq "Ok"
  end

  describe 'streaming' do
    context 'GET' do
      it "streams response body" do
        curl_result = DeepStruct.wrap({status: 200, body: nil})
        allow(Pebblebed::Http).to receive(:stream_get).with(
          URI.parse("http://example.org/"),
          {"session" => "session_key"},
          anything) { |_, _, options|
          options[:on_data].call("hello")
        }.and_return(curl_result)

        buf = ""
        client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
        result = client.stream(:get, '/', {}, on_data: ->(data) {
          buf << data
        })
        expect(buf).to eq "hello"
        expect(result.status).to eq 200
        expect(result.body).to eq nil
      end
    end
  end

end
