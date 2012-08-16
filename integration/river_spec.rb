require 'digest'
require 'pebblebed/uid'
require 'pebblebed/river'

# Note to readers. This is verbose and ugly
# because I'm trying to understand what I'm doing.
# When I do understand it, I'll clean up the tests.
# Until then, please just bear with me.
# Or explain it to me :)
describe Pebblebed::River do

  subject { Pebblebed::River.new('whatever') }

  after(:each) do
    subject.send(:bunny).queues.each do |name, queue|
      queue.purge
      queue.delete
    end
    subject.disconnect
  end

  it { subject.should_not be_connected }

  it "gets the name right" do
    subject.exchange_name.should eq('pebblebed.river.whatever')
  end

  context "in production" do
    subject { Pebblebed::River.new('production') }

    it "doesn't append the thing" do
      subject.exchange_name.should eq('pebblebed.river')
    end
  end

  it "connects" do
    subject.connect
    subject.should be_connected
  end

  it "disconnects" do
    subject.connect
    subject.should be_connected
    subject.disconnect
    subject.should_not be_connected
  end

  it "connects if you try to publish something" do
    subject.should_not be_connected
    subject.publish(:event => :test, :uid => 'klass:path$123', :attributes => {:a => 'b'})
    subject.should be_connected
  end

  it "connects if you try to talk to the exchange" do
    subject.should_not be_connected
    subject.send(:exchange)
    subject.should be_connected
  end

  describe "publishing" do

    it "gets selected messages" do
      queue = subject.queue(:name => 'thingivore', :path => 'rspec', :klass => 'thing')

      queue.message_count.should eq(0)
      subject.publish(:event => 'smile', :uid => 'thing:rspec$1', :attributes => {:a => 'b'})
      subject.publish(:event => 'frown', :uid => 'thing:rspec$2', :attributes => {:a => 'b'})
      subject.publish(:event => 'laugh', :uid => 'thing:testunit$3', :attributes => {:a => 'b'})
      sleep(0.1)
      queue.message_count.should eq(2)
    end

    it "gets everything if it connects without a key" do
      queue = subject.queue(:name => 'omnivore')

      queue.message_count.should eq(0)
      subject.publish(:event => 'smile', :uid => 'thing:rspec$1', :attributes => {:a => 'b'})
      subject.publish(:event => 'frown', :uid => 'thing:rspec$2', :attributes => {:a => 'b'})
      subject.publish(:event => 'laugh', :uid => 'testunit:rspec$3', :attributes => {:a => 'b'})
      sleep(0.1)
      queue.message_count.should eq(3)
    end

    it "sends messages as json" do
      queue = subject.queue(:name => 'eatseverything')
      subject.publish(:event => 'smile', :source => 'rspec', :uid => 'klass:path$1', :attributes => {:a => 'b'})
      sleep(0.1)
      JSON.parse(queue.pop[:payload])['uid'].should eq('klass:path$1')
    end
  end

  it "subscribes" do
    queue = subject.queue(:name => 'alltestivore', :path => 'rspec|testunit', :klass => 'thing')

    queue.message_count.should eq(0)
    subject.publish(:event => 'smile', :uid => 'thing:rspec$1', :attributes => {:a => 'b'})
    subject.publish(:event => 'frown', :uid => 'thing:rspec$2', :attributes => {:a => 'b'})
    subject.publish(:event => 'laugh', :uid => 'thing:testunit$3', :attributes => {:a => 'b'})
    sleep(0.1)
    queue.message_count.should eq(3)
  end

  it "is a durable queue" do
    queue = subject.queue(:name => 'adurablequeue', :path => 'katrina')
    subject.publish(:event => 'test', :uid => 'person:katrina$1', :attributes => {:a => rand(1000)}, :persistent => false)
  end
end