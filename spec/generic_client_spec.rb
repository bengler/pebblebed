require 'spec_helper'

describe Pebblebed::GenericClient do 
  it "always forwards the session key" do
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    client.service_params({})['session'].should eq "session_key"
  end

  it "always converts urls to URI-objects" do
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    client.instance_variable_get(:@root_url).class.name.should eq ("URI::HTTP")
  end

  it "knows how to generate a service specific url" do
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    client.service_url("/test").to_s.should eq "http://example.org/test"
    client.service_url("").to_s.should eq "http://example.org"
  end

  it "wraps JSON-results in a deep struct" do
    curl_result = DeepStruct.wrap({status:200, body:'{"hello":"world"}'})
    Pebblebed::Http.stub(:get).and_return(curl_result)
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    result = client.get "/"
    result.class.name.should eq "DeepStruct::HashWrapper"
    result.hello.should eq "world"
  end

  it "does not wrap non-json results" do
    curl_result = DeepStruct.wrap({status:200, body:'Ok'})
    Pebblebed::Http.stub(:get).and_return(curl_result)
    client = Pebblebed::GenericClient.new("session_key", "http://example.org/")
    result = client.get "/"
    result.class.name.should eq "String"
    result.should eq "Ok"
  end

end
