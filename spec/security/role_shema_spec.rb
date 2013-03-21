require 'spec_helper'
require 'deepstruct'
require 'pebblebed/config'
require 'pebblebed/connector'
require 'pebblebed/security/role_schema'


describe Pebblebed::Security::RoleSchema do

  class InvalidRoleSchema < Pebblebed::Security::RoleSchema
    role :guest, :capabilities => [], :requirements => []
    role :contributor, :capabilities => [:comment, :kudo], :requirements => [:logged_in]
  end

  class CustomRoleSchema < Pebblebed::Security::RoleSchema
    role :guest, :capabilities => [], :requirements => []
    role :contributor, :capabilities => [:comment, :kudo], :requirements => [:logged_in, :verified_mobile]

    def check_logged_in
      return false
    end

    def check_verified_mobile
      return false
    end

  end

  let(:connector) {
    Pebblebed::Connector.new("session_key")
  }

  let(:guest) {
    DeepStruct.wrap({})
  }

  let(:user) {
    DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false})
  }

  context "invalid role schema" do

    let(:schema) {
      InvalidRoleSchema.new(connector, guest)
    }

    it "raises a NoMethodError with explaination about what you need to implement" do
      expect {
        schema.role
        }.to raise_error(NoMethodError, "You must implement method named :check_logged_in that returns true or false")
    end
  end
  context "as guest" do

    let(:schema) {
      CustomRoleSchema.new(connector, guest)
    }

    it "has connector and identity attributes" do
      schema.connector.should eq connector
      schema.identity.should eq guest
    end

    it "has the correct roles defined" do
      CustomRoleSchema.roles.should ==  [{:capabilities=>[], :requirements=>[], :name=>:guest, :role_rank=>0}, {:capabilities=>[:comment, :kudo], :requirements=>[:logged_in, :verified_mobile], :name=>:contributor, :role_rank=>1}]
    end

    it "returns the current role" do
      schema.role.should == {
        :current => :guest,
        :capabilities => [],
        :upgrades => {
          :contributor => [:logged_in, :verified_mobile]
        }
      }
    end


  end

end
