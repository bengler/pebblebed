require 'spec_helper'
require 'pebblebed/config'
require 'pebblebed/connector'

describe Pebblebed do
  it "has a nice dsl that configures stuff" do
    Pebblebed.config do
      host "example.org"
      memcached $memcached
      service :checkpoint
    end

    Pebblebed.host.should eq "example.org"
    Pebblebed.memcached.should eq $memcached
    Pebblebed::Connector.instance_methods.should include :checkpoint
  end

  it "can calculate the root uri of any pebble" do
    Pebblebed.config do
      service :checkpoint
      service :foobar, :version => 2
    end
    Pebblebed.host = "example.org"
    Pebblebed.root_url_for(:checkpoint).to_s.should eq "http://example.org/api/checkpoint/v1/"
    Pebblebed.root_url_for(:checkpoint, :host => 'checkpoint.dev').to_s.should eq "http://checkpoint.dev/api/checkpoint/v1/"
    Pebblebed.root_url_for(:foobar).to_s.should eq "http://example.org/api/foobar/v2/"
  end

end
