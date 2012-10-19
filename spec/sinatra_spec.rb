# encoding: utf-8

require 'pebblebed'
require 'pebblebed/sinatra'
require 'sinatra'
require 'rack/test'

class TestApp < Sinatra::Base
  register Sinatra::Pebblebed

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
    Pebblebed::Connector.any_instance.stub(:checkpoint).and_return checkpoint
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
end
