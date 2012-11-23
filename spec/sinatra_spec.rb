# encoding: utf-8
require 'pebblebed'
require 'pebblebed/sinatra'
require 'sinatra/base'
require 'rack/test'
require 'spec_helper'

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

  def app
    TestApp
  end

  let(:guest) { DeepStruct.wrap({}) }
  let(:alice) { DeepStruct.wrap(:identity => {:id => 1, :god => false}) }
  let(:odin) { DeepStruct.wrap(:identity => {:id => 2, :god => true}) }

  let(:checkpoint) { stub(:get => identity, :service_url => 'http://example.com') }

  before :each do
    TestApp.any_instance.stub(:current_session).and_return "validsessionyesyesyes"
    Pebblebed::Connector.any_instance.stub(:checkpoint).and_return checkpoint
  end

  let(:random_session) { rand(36**128).to_s(36) }

  before :each do
    # Make sure the app get an uniqie session key for every received request
    TestApp.any_instance.stub(:current_session) { random_session }
  end

  context "a guest" do
    let(:identity) { guest }

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
    let(:identity) { alice }

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
    let(:identity) { odin }

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
    let(:identity) { guest }
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

  describe "current identity caching" do
    let(:identity) { alice }

    it "will not cache current_identity by default" do
      checkpoint.should_receive(:get).twice
      get '/private'
      get '/private'
    end

    it "can be configured to cache current identity" do
      session = random_session
      app.set :cache_current_identity, true
      checkpoint.should_receive(:get).once
      get '/private'
      get '/private'
    end
  end

  describe "identity caching disabled when no current user" do
    let(:identity) { {} }

    it "will not cache identity when there is no current identity" do
      identity = nil
      app.set :cache_current_identity, true
      checkpoint.should_receive(:get).twice
      get '/private'
      get '/private'
    end
  end
end
