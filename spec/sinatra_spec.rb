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

  get '/group' do
    require_access_to_path("testrealm.specialgroup.123")
    "You are granted access to this content"
  end

  get '/root' do
    require_god
    "You are most powerful"
  end

  post '/create/:uid' do |uid|
    require_action_allowed(:create, uid)
    "You are creative"
  end

  post '/create2/:uid' do |uid|
    require_action_allowed(:create, uid, :default => false)
    "You are creative"
  end

  post '/create3/:uid' do |uid|
    require_action_allowed(:create, uid, :default => true)
    "You are creative"
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
      expect(last_response.body).to eq('You are a guest here')
    end

    it "can assign a provisional identity" do
      get '/public', :provisional => 'yes'
      expect(last_response.status).to eq(302)
    end

    specify "cannot see private endpoints" do
      get '/private'
      expect(last_response.status).to eq(403)
    end

    it "cannot see root endpoints" do
      get '/root'
      expect(last_response.status).to eq(403)
    end
  end

  context "as a user" do
    before(:each) { user! }

    specify "can see public endpoint" do
      get '/public'
      expect(last_response.body).to eq('You are a guest here')
    end

    specify "can see private endpoints" do
      get '/private'
      expect(last_response.body).to eq('You are logged in')
    end

    it "cannot see root endpoints" do
      get '/root'
      expect(last_response.status).to eq(403)
    end
  end

  context "as a god" do
    before(:each) { god!(:session => random_session) }

    specify "can see public endpoint" do
      get '/public'
      expect(last_response.body).to eq('You are a guest here')
    end

    specify "can see private endpoints" do
      get '/private'
      expect(last_response.body).to eq('You are logged in')
    end

    it "cannot see root endpoints" do
      get '/root'
      expect(last_response.body).to eq('You are most powerful')
    end
  end

  describe "with access groups control" do
    let(:checkpoint) {
      checkpoint = double(:service_url => 'http://example.com')
      checkpoint
    }
    context "as a guest" do
      specify "not allowed" do
        guest!
        get '/group'
        expect(last_response.status).to eq(403)
      end
    end
    context "as a god" do
      specify "allowed without policy check" do
        god!(:session => random_session)
        get '/group'
        expect(last_response.body).to eq("You are granted access to this content")
      end
    end
    context "as user without grants" do
      specify "is disallowed" do
        user!
        expect(checkpoint).to receive(:get).with("/identities/me").and_return(DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false}))
        expect(checkpoint).to receive(:get).with("/identities/1/access_to/testrealm.specialgroup.123").and_return(DeepStruct.wrap(:access => {:granted => false}))
        Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)
        get '/group'
        expect(last_response.status).to eq(403)
      end
    end
    context "as user with grants" do
      specify "is allowed" do
        user!
        expect(checkpoint).to receive(:get).with("/identities/me").and_return(DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false}))
        expect(checkpoint).to receive(:get).with("/identities/1/access_to/testrealm.specialgroup.123").and_return(DeepStruct.wrap(:access => {:granted => true}))
        Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)
        get '/group'
        expect(last_response.body).to eq("You are granted access to this content")
      end
    end
  end

  describe "with checkpoint psm2 callbacks" do
    let(:checkpoint) {
      checkpoint = double(:service_url => 'http://example.com')
      checkpoint
    }
    context "as a guest" do
      specify "not allowed" do
        guest!
        post '/create/post.foo:testrealm'
        expect(last_response.status).to eq(403)
      end
    end
    context "as a god" do
      specify "allowed without callbacks" do
        god!(:session => random_session)
        post '/create/post.foo:testrealm'
        expect(last_response.body).to eq("You are creative")
      end
    end
    context "as user without permissions" do
      specify "is disallowed" do
        user!
        expect(checkpoint).to receive(:get).with("/identities/me").and_return(DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false}))
        expect(checkpoint).to receive(:post).with("/callbacks/allowed/create/post.foo:testrealm").and_return(DeepStruct.wrap(:allowed => false, :reason => "You are not worthy!"))
        Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)
        post '/create/post.foo:testrealm'
        expect(last_response.status).to eq(403)
        expect(last_response.body).to eq(":create denied for post.foo:testrealm : You are not worthy!")
      end
    end
    context "as user with permissions" do
      specify "is allowed" do
        user!
        expect(checkpoint).to receive(:get).with("/identities/me").and_return(DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false}))
        expect(checkpoint).to receive(:post).with("/callbacks/allowed/create/post.foo:testrealm").and_return(DeepStruct.wrap(:allowed => true))
        Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)
        post '/create/post.foo:testrealm'
        expect(last_response.body).to eq("You are creative")
      end
      context "with options[:default] => false" do
        specify "is disallowed" do
          user!
          expect(checkpoint).to receive(:get).with("/identities/me").and_return(DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false}))
          expect(checkpoint).to receive(:post).with("/callbacks/allowed/create/post.foo:testrealm").and_return(DeepStruct.wrap(:allowed => "default"))
          Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)
          post '/create2/post.foo:testrealm'
          expect(last_response.status).to eq(403)
        end
      end
      context "with no options given and allowed = default" do
        specify "is disallowed" do
          user!
          expect(checkpoint).to receive(:get).with("/identities/me").and_return(DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false}))
          expect(checkpoint).to receive(:post).with("/callbacks/allowed/create/post.foo:testrealm").and_return(DeepStruct.wrap(:allowed => "default"))
          Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)
          post '/create/post.foo:testrealm'
          expect(last_response.status).to eq(403)
        end
      end
      context "with options[:default] => true" do
        specify "is allowed" do
          user!
          expect(checkpoint).to receive(:get).with("/identities/me").and_return(DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false}))
          expect(checkpoint).to receive(:post).with("/callbacks/allowed/create/post.foo:testrealm").and_return(DeepStruct.wrap(:allowed => "default"))
          Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)
          post '/create3/post.foo:testrealm'
          expect(last_response.body).to eq("You are creative")
        end
      end
    end
  end
end
