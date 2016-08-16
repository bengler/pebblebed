require 'spec_helper'
require 'pebblebed/river'
require 'pebblebed/uid'
require 'pebblebed/config'

describe Pebblebed::River do

  describe "routing keys" do

    Pebblebed.config do
      memcached 'MemcachedClient'
    end

    specify do
      options = {:event => 'created', :uid => 'post.awesome.event:feeds.bagera.whatevs$123'}
      expect(Pebblebed::River.route(options)).to eq('created._.post.awesome.event._.feeds.bagera.whatevs')
    end

    specify "event is required" do
      expect{ Pebblebed::River.route(:uid => 'whatevs') }.to raise_error ArgumentError
    end

    specify "uid is required" do
      expect{ Pebblebed::River.route(:event => 'whatevs') }.to raise_error ArgumentError
    end

  end
end
