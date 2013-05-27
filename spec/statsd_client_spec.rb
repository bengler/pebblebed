require 'spec_helper'
require 'pebblebed/clients/generic_client'
require 'pebblebed/clients/statsd_client'

class DummyCurlResult
  def initialize(status, url, body)
    @status, @url, @body = status, url, body
  end
  attr_reader :status, :url, :body
end

describe Pebblebed::GenericClient do

  let :statsd do
    Statsd.new('localhost')
  end

  let :client do
    Pebblebed::GenericClient.new("session_key", "http://example.org/")
  end

  let :s_client do
    Pebblebed::StatsdClient.new('bar', client, statsd)
  end

  describe '#perform' do
    it 'records metrics about call' do
      Pebblebed::Http.should_receive(:get).with(
        client.service_url("/foo"), client.service_params({})).and_return(
          DummyCurlResult.new(200, "/foo", "{}"))

      statsd.should_receive(:increment).with('client_calls').once.and_return(1)
      statsd.should_receive(:increment).with('client_calls_to_bar').once.and_return(1)

      statsd.should_receive(:timing).with('client_calls', be_kind_of(Numeric)).once.and_return(nil)
      statsd.should_receive(:timing).with('client_calls_to_bar', be_kind_of(Numeric)).once.and_return(nil)

      s_client.perform(:get, '/foo')
    end
  end

  describe '#service_url' do
    it 'delegates to inner client' do
      s_client.service_url("/test").should eq client.service_url('/test')
    end
  end

  describe '#service_params' do
    it 'delegates to inner client' do
      s_client.service_params({}).should eq client.service_params({})
    end
  end

end