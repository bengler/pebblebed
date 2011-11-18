require 'spec_helper'

describe Pebbles do
  it "has a nice dsl that configures stuff" do
    Pebbles.config do
      host "example.org"
      memcached "some value"
      service :checkpoint      
    end

    Pebbles.host.should eq "example.org"
    Pebbles.memcached.should eq "some value"
    Pebbles::Connector.instance_methods.should include :checkpoint
  end

  it "can calculate the root uri of any pebble" do
    Pebbles.config do
      service :checkpoint
      service :foobar, :version => 2
    end
    Pebbles.host = "example.org"
    Pebbles.root_url_for(:checkpoint).to_s.should eq "http://example.org/api/checkpoint/v1/"
    Pebbles.root_url_for(:checkpoint, :host => 'checkpoint.dev').to_s.should eq "http://checkpoint.dev/api/checkpoint/v1/"
    Pebbles.root_url_for(:foobar).to_s.should eq "http://example.org/api/foobar/v2/"
  end

end