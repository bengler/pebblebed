require 'spec_helper'
require 'json'

describe Pebblebed::CheckpointClient do

  let(:checkpoint_client) { Pebblebed::Connector.new('session_key')[:checkpoint] }

  describe "me" do
    let(:canned_response_for_me) {
          DeepStruct.wrap({:body=>{:identity => {:id => 1, :god => true}}.to_json})
        }

    it "returns current user identity upon request and caches it as an instance variable" do
      checkpoint_client = Pebblebed::Connector.new('session_key')[:checkpoint]

      Pebblebed::Http.should_receive(:get) { |url|
                url.path.should match("/identities/me")
                canned_response_for_me
              }.once
      checkpoint_client.me
      checkpoint_client.me
    end

    it "tells us whether we are dealing with god allmighty himself or just another average joe" do
      checkpoint_client = Pebblebed::Connector.new('session_key')[:checkpoint]
      Pebblebed::Http.should_receive(:get) { |url|
                url.path.should match("/identities/me")
                canned_response_for_me
              }.once
      checkpoint_client.god?.should eq true
    end
  end

  describe "cache_key_for_identity_id" do
    it "creates a nice looking cache key for memcache" do
      checkpoint_client = Pebblebed::Connector.new('session_key')[:checkpoint]
      checkpoint_client.cache_key_for_identity_id(2).should eq "identity:2"
    end
  end

  describe "find_identities" do
    let(:canned_response) {
      DeepStruct.wrap({:body=>
                         {:identities =>
                            [{:identity => {:id => 1}}, {:identity => {}}, {:identity => {:id => 3}}, {:identity => {}}]
                         }.to_json
                      })
    }

    describe "without memcache configured" do
      before(:each) do
        Pebblebed.config do
          host "checkpoint.dev"
          service :checkpoint
        end
      end

      it "issues an http request every time" do
        Pebblebed::Http.should_receive(:get).twice.and_return canned_response
        checkpoint_client.find_identities([1, 2])
        checkpoint_client.find_identities([1, 2])
      end
    end

    describe "with memcached configured" do
      before(:each) do
        Pebblebed.config do
          host "checkpoint.dev"
          memcached $memcached
          service :checkpoint
        end
      end

      it "issues an http request and caches it" do
        Pebblebed::Http.should_receive(:get).once.and_return(canned_response)
        checkpoint_client.find_identities([1, 2])
        checkpoint_client.find_identities([1, 2])

        $memcached.get(checkpoint_client.cache_key_for_identity_id(1)).should eq({"id"=>1})
        $memcached.get(checkpoint_client.cache_key_for_identity_id(2)).should eq({})
      end

      it "returns exactly the same data no matter if it is cached or originating from a request" do
        Pebblebed::Http.should_receive(:get).once.and_return(canned_response)

        http_requested_result = checkpoint_client.find_identities([1, 2, 3])
        cached_result = checkpoint_client.find_identities([1, 2, 3])

        http_requested_result.unwrap.should eq cached_result.unwrap
      end

      it "issues a request only for not previously cached identities" do
        Pebblebed::Http.should_receive(:get) { |url|
          url.path.should match("/identities/1,2,4")
          canned_response
        }.once
        checkpoint_client.find_identities([1, 2, 4])

        Pebblebed::Http.should_receive(:get) { |url|
          url.path.should match("/identities/3,") # Note the extra comma. Will ensure that a list is returned
          canned_response
        }.once
        checkpoint_client.find_identities([1, 2, 3, 4])
      end

      it "will always return identities in the order they are requested" do
        Pebblebed::Http.should_receive(:get).once.and_return(canned_response)

        checkpoint_client.find_identities([1, 2, 3, 4])
        identities = checkpoint_client.find_identities([4, 3, 2, 1])
        identities[1].id.should eq 3
        identities[3].id.should eq 1
      end
    end
  end
end