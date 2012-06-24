require 'spec_helper'
require 'pebblebed/river'
require 'pebblebed/uid'

describe Pebblebed::River do

  describe "routing keys" do

    specify do
      options = {:event => 'created', :uid => 'post.awesome.event:feeds.bagera.whatevs$123'}
      Pebblebed::River.route(options).should eq('created._.post.awesome.event._.feeds.bagera.whatevs')
    end

    specify "event is required" do
      ->{ Pebblebed::River.route(:uid => 'whatevs') }.should raise_error ArgumentError
    end

    specify "uid is required" do
      ->{ Pebblebed::River.route(:event => 'whatevs') }.should raise_error ArgumentError
    end

  end
end
