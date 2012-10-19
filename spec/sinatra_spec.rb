# encoding: utf-8

require 'pebblebed'
require 'pebblebed/sinatra'
require 'sinatra'
require 'rack/test'

class TestApp < Sinatra::Base
  register Sinatra::Pebblebed

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

end

describe Sinatra::Pebblebed do
  include Rack::Test::Methods

  def app
    TestApp
  end

  let(:guest) { DeepStruct.wrap(:identity => {}) }
  let(:alice) { DeepStruct.wrap(:identity => {:id => 1, :god => false}) }
  let(:odin) { DeepStruct.wrap(:identity => {:id => 2, :god => true}) }

  let(:checkpoint) { stub(:get => identity) }

  before :each do
    Pebblebed::Connector.any_instance.stub(:checkpoint).and_return checkpoint
  end

  context "a guest" do
    let(:identity) { guest }

    specify "can see public endpoint" do
      get '/public'
      last_response.body.should == 'You are a guest here'
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

end
