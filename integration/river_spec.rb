require 'digest'
require 'pebblebed/uid'
require 'pebblebed/river'
ENV['RACK_ENV'] = 'test'

# Note to readers. This is verbose and ugly
# because I'm trying to understand what I'm doing.
# When I do understand it, I'll clean up the tests.
# Until then, please just bear with me.
# Or explain it to me :)
describe Pebblebed::River do

  after(:each) do
    @queue.delete if @queue
    Pebblebed::River.purge
    Pebblebed::River.disconnect
  end

  it "is disconnected by default" do
    Pebblebed::River.should_not be_connected
  end

  it "will connect if you tell it to" do
    Pebblebed::River.connect
    Pebblebed::River.should be_connected
  end

  it "will connect if you try to publish something" do
    # guard
    Pebblebed::River.should_not be_connected

    Pebblebed::River.publish(:event => :test, :uid => 'klass:path$123', :attributes => {:a => 'b'})
    Pebblebed::River.should be_connected
  end

  it "connects if you try to talk to the exchange" do
    # guard
    Pebblebed::River.should_not be_connected

    Pebblebed::River.exchange
    Pebblebed::River.should be_connected
  end

  it "disconnects" do
    Pebblebed::River.connect
    Pebblebed::River.should be_connected

    Pebblebed::River.disconnect
    Pebblebed::River.should_not be_connected
  end

  describe "the exchange" do

    subject { Pebblebed::River.exchange } # defaults to the RACK_ENV variable
    its(:name) { should eq('pebblebed.river.test') }
    its(:type) { should eq(:topic) }

    context "in production" do
      subject { Pebblebed::River.exchange('production') }

      its(:name) { should eq('pebblebed.river') }
    end

    context "in staging" do
      subject { Pebblebed::River.exchange('staging') }

      its(:name) { should eq('pebblebed.river.staging') }
    end
  end

  describe "publishing" do

    it "gets selected messages" do
      @queue = Pebblebed::River.queue_me(:name => 'thingivore', :path => 'rspec', :klass => 'thing')

      @queue.message_count.should eq(0)
      Pebblebed::River.publish(:event => 'smile', :uid => 'thing:rspec$1', :attributes => {:a => 'b'})
      Pebblebed::River.publish(:event => 'frown', :uid => 'thing:rspec$2', :attributes => {:a => 'b'})
      Pebblebed::River.publish(:event => 'laugh', :uid => 'thing:testunit$3', :attributes => {:a => 'b'})
      sleep(0.1)
      @queue.message_count.should eq(2)
    end

    it "gets everything if it connects without a key" do
      @queue = Pebblebed::River.queue_me(:name => 'omnivore')

      @queue.message_count.should eq(0)
      Pebblebed::River.publish(:event => 'smile', :uid => 'thing:rspec$1', :attributes => {:a => 'b'})
      Pebblebed::River.publish(:event => 'frown', :uid => 'thing:rspec$2', :attributes => {:a => 'b'})
      Pebblebed::River.publish(:event => 'laugh', :uid => 'testunit:rspec$3', :attributes => {:a => 'b'})
      sleep(0.1)
      @queue.message_count.should eq(3)
    end

    it "sends messages as json" do
      @queue = Pebblebed::River.queue_me(:name => 'eatseverything')
      Pebblebed::River.publish(:event => 'smile', :source => 'rspec', :uid => 'klass:path$1', :attributes => {:a => 'b'})
      sleep(0.1)
      JSON.parse(@queue.pop[:payload])['uid'].should eq('klass:path$1')
    end
  end

  it "subscribes" do
    @queue = Pebblebed::River.queue_me(:name => 'alltestivore', :path => 'rspec|testunit', :klass => 'thing')

    @queue.message_count.should eq(0)
    Pebblebed::River.publish(:event => 'smile', :uid => 'thing:rspec$1', :attributes => {:a => 'b'})
    Pebblebed::River.publish(:event => 'frown', :uid => 'thing:rspec$2', :attributes => {:a => 'b'})
    Pebblebed::River.publish(:event => 'laugh', :uid => 'thing:testunit$3', :attributes => {:a => 'b'})
    sleep(0.1)
    @queue.message_count.should eq(3)
  end

  it "is a durable queue" do
    @queue = Pebblebed::River.queue_me(:name => 'adurablequeue', :path => 'katrina')
    Pebblebed::River.publish(:event => 'test', :uid => 'person:katrina$1', :attributes => {:a => rand(1000)}, :persistent => false)
  end
end
