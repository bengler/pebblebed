# encoding: utf-8

require 'spec_helper'
require 'yajl/json_gem'
require 'pebblebed/http'
require 'pebblebed/config'
require 'deepstruct'

describe Pebblebed::Http do

  Pebblebed.config do
    memcached "MemcachedClient"
  end

  def mock_pebble
    @mp ||= MockPebble.new
  end

  let :pebble_url do
    "http://localhost:8666/api/mock/v1/echo?foo=bar"
  end

  before :all do
    Pebblebed::Http.connect_timeout = nil
    Pebblebed::Http.read_timeout = nil
    Pebblebed::Http.write_timeout = nil

    # Starts the mock pebble at localhost:8666/api/mock/v1
    mock_pebble.start
  end

  after :all do
    mock_pebble.shutdown
    # give webrick some time to cool down
    sleep 0.1
  end

  it "knows how to pack params into a http query string" do
    expect(Pebblebed::Http.send(:url_with_params, URI("/dingo/"), {a:1})).to eq "/dingo/?a=1"
  end

  it "knows how to combine url and parmas with results of pathbuilder" do
    url, params = Pebblebed::Http.send(:url_and_params_from_args, URI("http://example.org/api"), {a:1}) do
      foo.bar(:b => 2)
    end
    expect(params).to eq(:a => 1, :b => 2)
    expect(url.to_s).to eq "http://example.org/api/foo/bar"
  end

  it "handles urls as strings" do
    url, params = Pebblebed::Http.send(:url_and_params_from_args, "http://example.org/api", {a:1}) do
      foo.bar(:b => 2)
    end
    expect(params).to eq(:a => 1, :b => 2)
    expect(url.to_s).to eq "http://example.org/api/foo/bar"
  end

  it "raises an HttpNotFoundError if there is a 404 error" do
    expect { Pebblebed::Http.send(:handle_http_errors, DeepStruct.wrap(status: 404, url: "/foobar", body: "Not found")) }.to raise_error Pebblebed::HttpNotFoundError
  end

  it "includes the url of the failed resource in the error message" do
    expect { Pebblebed::Http.send(:handle_http_errors, DeepStruct.wrap(status: 404, url: "/nosuchresource", body: "Not found")) }.to raise_error Pebblebed::HttpNotFoundError, /\/nosuchresource/
  end

  it "raises an HttpError if there is any other http-error" do
    expect { Pebblebed::Http.send(:handle_http_errors, DeepStruct.wrap(status: 400, url: "/foobar", body: "Oh noes")) }.to raise_error Pebblebed::HttpError
  end

  it "encodes posts and puts as json if the params is a hash" do
    ['post', 'put'].each do |method|
      response = Pebblebed::Http.send(method.to_sym, pebble_url, {hello:'world'})
      result = JSON.parse(response.body)
      expect(result["CONTENT_TYPE"]).to match(%r{^application/json\b}i)
      expect(JSON.parse(result["BODY"])['hello']).to eq 'world'
    end
  end

  it "encodes posts and puts as text/plain if param is string" do
    ['post', 'put'].each do |method|
      response = Pebblebed::Http.send(method.to_sym, pebble_url, "Hello world")
      result = JSON.parse(response.body)
      expect(result["CONTENT_TYPE"]).to match(%r{^text/plain\b}i)
      expect(result["BODY"]).to eq "Hello world"
    end
  end

  it "encodes gets as url params" do
    params = {
      'min' => {
        'hits' => '1'
      },
      'limit' => '2'
    }
    params['fields'] = {'document.category' => 'test'}
    params['max'] = {'hits' => '3'}
    response = Pebblebed::Http.get(pebble_url, params)
    result = JSON.parse(response.body)
    expect(result["QUERY_STRING"]).to eq "min[hits]=1&limit=2&fields[document.category]=test&max[hits]=3&foo=bar"
  end

  describe 'streaming' do
    context 'GET' do
      it "streams response body" do
        buf = ""
        response = Pebblebed::Http.stream_get(pebble_url, {hello: 'world'},
          on_data: ->(data) {
            buf << data
          })
        result = JSON.parse(buf)
        expect(result["QUERY_STRING"]).to eq "hello=world&foo=bar"
        expect(response.body).to eq ''
      end

      it "supports multiple sequential streaming request" do
        10.times do
          buf = ""
          response = Pebblebed::Http.stream_get(pebble_url, {hello: 'world'},
            on_data: ->(data) {
              buf << data
            })
          result = JSON.parse(buf)
          expect(result["QUERY_STRING"]).to eq "hello=world&foo=bar"
          expect(response.body).to eq ''
        end
      end

      it "sends headers" do
        Excon.stub({:method => :get}) { |params|
          expect(params[:headers]['Accept']).to eq 'application/x-ndjson'
          {body: '', headers: {}, status: 200}
        }

        Pebblebed::Http.stream_get("http://example.org/", {},
          headers: {'Accept' => 'application/x-ndjson'},
          on_data: ->() {})
      end
    end
  end

  it "enforces read timeout" do
    Pebblebed::Http.read_timeout = 1
    expect {
      Pebblebed::Http.get(pebble_url, {slow: '30'})
    }.to raise_error(Pebblebed::HttpTimeoutError)
    expect {
      Pebblebed::Http.get(pebble_url, {slow: '0.5'})
    }.not_to raise_error
  end

  describe 'retrying' do
    run_count = 0

    before do
      Excon.stub({:method => :post}) {
        raise Excon::Errors::SocketError.new(Exception.new "Mock Error")
      }
      Excon.stub({:method => :get}) { |params|
        run_count += 1
        if run_count <= 10
          raise Excon::Errors::SocketError.new(Exception.new "Mock Error")
        end
        {:body => params[:body], :headers => params[:headers], :status => 200}
      }
    end

    after do
      Excon.stubs.clear
    end

    it "post with error doesn't try again" do
      expect {
        Pebblebed::Http.post(pebble_url, {hello: 'world'})
      }.to raise_error(Pebblebed::HttpSocketError)
    end

    it "get request tries one more time" do
      expect {
        Pebblebed::Http.get(pebble_url, {hello: 'world'})
      }.to raise_error(Pebblebed::HttpSocketError)
      expect(run_count).to be > 2
    end

  end
end
