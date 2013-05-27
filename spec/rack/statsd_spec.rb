require 'spec_helper'
require 'pebblebed/rack/statsd'

class DummyApp
  def call(env)
    [200, 'OK', {}]
  end
end

describe Pebblebed::Rack::Statsd do

  let :statsd do
    Statsd.new('localhost')
  end

  let :app do
    DummyApp.new
  end

  describe '#call' do
    it 'records metrics about call' do
      statsd.should_receive(:increment).with('requests_total').once.and_return(1)
      statsd.should_receive(:timing).with('request_time', be_kind_of(Numeric)).once.and_return(1)

      handler = Pebblebed::Rack::Statsd.new(app)
      handler.statsd = statsd

      result = handler.call({})
      result.should eq [200, 'OK', {}]
    end
  end

end