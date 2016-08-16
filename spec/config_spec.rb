require 'spec_helper'
require 'pebblebed/config'
require 'pebblebed/connector'

describe Pebblebed do
  it "has a nice dsl that configures stuff" do
    Pebblebed.config do
      host "example.org"
      memcached "MemcachedClient"
      session_cookie "my.session"
      service :checkpoint
    end

    expect(Pebblebed.host).to eq "example.org"
    expect(Pebblebed.memcached).to eq "MemcachedClient"
    expect(Pebblebed.session_cookie).to eq "my.session"
    expect(Pebblebed::Connector.instance_methods).to include :checkpoint
  end

  it "raises an error when memcached is used but not configured" do
    Pebblebed.memcached = nil
    expect {Pebblebed.memcached}.to raise_error RuntimeError
  end

  it "has a default name of 'checkpoint.session' for the session cookie" do
    Pebblebed.session_cookie = nil
    expect(Pebblebed.session_cookie).to eq "checkpoint.session"
  end

  it "can calculate the root uri of any pebble" do
    Pebblebed.config do
      service :checkpoint
      service :foobar, :version => 2
    end
    Pebblebed.host = "example.org"
    expect(Pebblebed.root_url_for(:checkpoint).to_s).to eq "http://example.org/api/checkpoint/v1/"
    expect(Pebblebed.root_url_for(:checkpoint, :host => 'checkpoint.dev').to_s).to eq "http://checkpoint.dev/api/checkpoint/v1/"
    expect(Pebblebed.root_url_for(:foobar).to_s).to eq "http://example.org/api/foobar/v2/"
  end

  it "allows the path of a pebble to be overridden" do
    Pebblebed.config do
      service :checkpoint, :path => '/my_api/my_checkpoint'
      service :foobar, :version => 2
    end
    Pebblebed.host = "example.org"
    expect(Pebblebed.root_url_for(:checkpoint).to_s).to eq "http://example.org/my_api/my_checkpoint/v1/"
    expect(Pebblebed.root_url_for(:checkpoint, :host => 'checkpoint.dev').to_s).to eq "http://checkpoint.dev/my_api/my_checkpoint/v1/"
    expect(Pebblebed.root_url_for(:foobar).to_s).to eq "http://example.org/api/foobar/v2/"
  end

  it "allows the host of a pebble to be overridden" do
    Pebblebed.config do
      service :checkpoint, host: 'example.net'
    end
    Pebblebed.host = "example.org"
    expect(Pebblebed.root_url_for(:checkpoint).to_s).to eq "http://example.net/api/checkpoint/v1/"
    expect(Pebblebed.root_url_for(:checkpoint, :host => 'checkpoint.dev').to_s).to eq "http://checkpoint.dev/api/checkpoint/v1/"
  end

  it "works with pebbles that are exposed via https" do
    Pebblebed.config do
      service :checkpoint
      service :foobar, :version => 2
    end
    Pebblebed.base_url = "https://example.org"
    expect(Pebblebed.root_url_for(:checkpoint).to_s).to eq "https://example.org/api/checkpoint/v1/"
    expect(Pebblebed.root_url_for(:checkpoint, :base_uri => 'https://checkpoint.dev').to_s).to eq "https://checkpoint.dev/api/checkpoint/v1/"
    expect(Pebblebed.root_url_for(:foobar).to_s).to eq "https://example.org/api/foobar/v2/"
  end

  it "allows passed in parameters to take precedence" do
    Pebblebed.config do
      service :checkpoint
      service :foobar, :version => 2
    end
    Pebblebed.base_url = "https://example.org"
    expect(Pebblebed.root_url_for(:checkpoint, :host => 'checkpoint.dev').to_s).to eq "http://checkpoint.dev/api/checkpoint/v1/"
  end

  it "raises an error if :host and :base_uri are both specified as parameters" do
    Pebblebed.config do
      service :checkpoint
    end
    expect {Pebblebed.root_url_for(:checkpoint, :base_uri => 'https://checkpoint.dev', :host => 'checkpoint.dev')}.to raise_error RuntimeError
    expect {Pebblebed.root_url_for(:checkpoint, :base_url => 'https://checkpoint.dev', :host => 'checkpoint.dev')}.to raise_error RuntimeError
  end

  it "request_uri takes precedence over host" do
    Pebblebed.config do
      host "example.net"
      service :checkpoint
      service :foobar, :version => 2
    end
    Pebblebed.base_url = "https://example.org"
    expect(Pebblebed.root_url_for(:checkpoint).to_s).to eq "https://example.org/api/checkpoint/v1/"
    expect(Pebblebed.root_url_for(:checkpoint, :base_uri => 'https://checkpoint.dev').to_s).to eq "https://checkpoint.dev/api/checkpoint/v1/"
  end
end
