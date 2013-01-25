# encoding: utf-8
require 'pebblebed'
require 'pebblebed/sinatra'
require 'sinatra/base'
require 'rack/test'
require 'spec_helper'
require 'pebblebed/rspec_helper'

class TestApp < Sinatra::Base
  register Sinatra::Pebblebed

  set :show_exceptions, :after_handler

  assign_provisional_identity :unless => lambda {
    params[:provisional] != 'yes'
  }

  get '/public' do
    "You are a guest here"
  end

  get '/private' do
    require_identity
    "You are logged in"
  end

  get '/root' do
    require_god
    "You are most powerful"
  end

  get '/nonexistant' do
    raise Pebblebed::HttpNotFoundError, "Not found /nonexistant"
  end

end

describe Sinatra::Pebblebed do
  include Rack::Test::Methods
  include Pebblebed::RSpecHelper

  def app
    TestApp
  end

  let(:random_session) { rand(36**128).to_s(36) }

  context "a guest" do
    before(:each) { guest! }

    specify "can see public endpoint" do
      get '/public'
      last_response.body.should == 'You are a guest here'
    end

    it "can assign a provisional identity" do
      get '/public', :provisional => 'yes'
      last_response.status.should == 302
    end

    specify "cannot see private endpoints" do
      get '/private'
      last_response.status.should == 403
    end

    it "cannot see root endpoints" do
      get '/root'
      last_response.status.should == 403
    end
  end

  context "as a user" do
    before(:each) { user! }

    specify "can see public endpoint" do
      get '/public'
      last_response.body.should == 'You are a guest here'
    end

    specify "can see private endpoints" do
      get '/private'
      last_response.body.should == 'You are logged in'
    end

    it "cannot see root endpoints" do
      get '/root'
      last_response.status.should == 403
    end
  end

  context "as a god" do
    before(:each) { god!(:session => random_session) }

    specify "can see public endpoint" do
      get '/public'
      last_response.body.should == 'You are a guest here'
    end

    specify "can see private endpoints" do
      get '/private'
      last_response.body.should == 'You are logged in'
    end

    it "cannot see root endpoints" do
      get '/root'
      last_response.body.should == 'You are most powerful'
    end
  end

  describe "error handling" do
    before(:each) { guest! }

    it "Adds graceful handling of HttpNotFoundError exceptions" do
      get '/nonexistant'
      last_response.status.should == 404
    end

    it "Gives the error message of HttpNotFoundError as response body" do
      get '/nonexistant'
      last_response.status.should == 404
      last_response.body.should == 'Not found /nonexistant'
    end
  end

  describe "identity caching" do

    context "with logged in user" do
      before(:each) { user!(:session => random_session) }
      let(:checkpoint) { Pebblebed::Connector.new.checkpoint }

      it "is not turned on by default" do
        checkpoint.should_receive(:get).twice
        get '/private'
        get '/private'
      end

      it "can be turned on" do
        app.set :cache_current_identity, true
        checkpoint.should_receive(:get).once
        get '/private'
        get '/private'
      end

      context "with guest user" do
        before(:each) { guest! }

        it "is disabled" do
          app.set :cache_current_identity, true
          checkpoint.should_receive(:get).twice
          get '/private'
          get '/private'
        end
      end
    end

  end
end
