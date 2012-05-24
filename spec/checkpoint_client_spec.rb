require 'spec_helper'

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

  describe "find_identities" do
    let(:canned_response) {
      DeepStruct.wrap({:body=>
                         {:identities =>
                            [{:identity => {:id => 1}}, {:identity => {}}, {:identity => {:id => 3}}, {:identity => {}}]
                         }.to_json
                      })
    }

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
end
