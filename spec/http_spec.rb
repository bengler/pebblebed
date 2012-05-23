# encoding: utf-8

require 'spec_helper'
require 'yajl/json_gem'

describe Pebblebed::Http do 

  let :mock_pebble do
    MockPebble.new
  end

  let :pebble_url do
    "http://localhost:8666/api/mock/v1/echo"
  end

  before :all do
    # Starts the mock pebble at localhost:8666/api/mock/v1
    mock_pebble.start
  end

  after :all do
    mock_pebble.shutdown
  end

  it "knows how to pack params into a http query string" do
    Pebblebed::Http.send(:url_with_params, URI("/dingo/"), {a:1}).should eq "/dingo/?a=1"
  end

  it "knows how to combine url and parmas with results of pathbuilder" do
    url, params = Pebblebed::Http.send(:url_and_params_from_args, URI("http://example.org/api"), {a:1}) do
      foo.bar(:b => 2)
    end
    params.should eq(:a => 1, :b => 2)
    url.to_s.should eq "http://example.org/api/foo/bar"
  end

  it "handles urls as strings" do
    url, params = Pebblebed::Http.send(:url_and_params_from_args, "http://example.org/api", {a:1}) do
      foo.bar(:b => 2)
    end
    params.should eq(:a => 1, :b => 2)
    url.to_s.should eq "http://example.org/api/foo/bar"
  end

  it "raises an exception if there is a http-error" do
    -> { Pebblebed::Http.send(:handle_http_errors, DeepStruct.wrap(status:400, url:"/foobar", body:"Oh noes")) }.should raise_error Pebblebed::HttpError
  end

  it "encodes posts and puts as json if the params is a hash" do
    ['post', 'put'].each do |method|    
      response = Pebblebed::Http.send(method.to_sym, pebble_url, {hello:'world'})
      result = JSON.parse(response.body)
      result["CONTENT_TYPE"].should =~ %r{application/json; charset=utf-8}i
      JSON.parse(result["BODY"])['hello'].should eq 'world'
    end
  end

  it "encodes posts and puts as text/plain if param is string" do
    ['post', 'put'].each do |method|    
      response = Pebblebed::Http.send(method.to_sym, pebble_url, "Hello world")
      result = JSON.parse(response.body)
      result["CONTENT_TYPE"].should =~ %r{text/plain; charset=utf-8}i
      result["BODY"].should eq "Hello world"
    end
  end

  it "encodes gets as url params" do
    response = Pebblebed::Http.get(pebble_url, {hello: 'world'})
    result = JSON.parse(response.body)
    result["QUERY_STRING"].should eq "hello=world"
  end

end
