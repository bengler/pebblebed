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
    role :identified, :capabilities => [:kudo], :requirements => [:logged_in]
    role :contributor, :capabilities => [:comment, :kudo], :requirements => [:logged_in, :verified_mobile]

    def check_logged_in
      return true if identity and identity['identity']
      false
    end

    def check_verified_mobile
      return true if identity and identity['identity'] and identity['identity']['verified_mobile']
      false
    end

  end

  let(:connector) {
    Pebblebed::Connector.new("session_key")
  }

  let(:guest) {
    DeepStruct.wrap({})
  }

  let(:contributor) {
    DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false})
  }

  let(:contributor_with_mobile) {
    DeepStruct.wrap(:identity => {:realm => 'testrealm', :id => 1, :god => false, :verified_mobile => true})
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

  context "basics" do
    let(:schema) {
      CustomRoleSchema.new(connector, guest)
    }

    it "has connector and identity attributes" do
      schema.connector.should eq connector
      schema.identity.should eq guest
    end

    it "has the correct roles defined" do
      CustomRoleSchema.roles.should ==  [{:capabilities=>[], :requirements=>[], :name=>:guest, :role_rank=>0}, {:capabilities=>[:kudo], :requirements=>[:logged_in], :name=>:identified, :role_rank=>1}, {:capabilities=>[:comment, :kudo], :requirements=>[:logged_in, :verified_mobile], :name=>:contributor, :role_rank=>2}]
    end
  end

  context "as guest" do

    let(:schema) {
      CustomRoleSchema.new(connector, guest)
    }

    it "returns the guest role" do
      schema.role.should == {:current=>:guest, :capabilities=>[], :upgrades=>{:identified=>[:logged_in], :contributor=>[:logged_in, :verified_mobile]}}
    end

  end

  context "as contributor" do

      context "with a contributor without verified mobile" do

        let(:schema) {
          CustomRoleSchema.new(connector, contributor)
        }

        it "returns the idenitified role" do
          schema.role.should == {:current=>:identified, :capabilities=>[:kudo], :upgrades=>{:contributor=>[:logged_in, :verified_mobile]}}
        end

      end

      context "with a contributor with a verified mobile" do

        let(:schema) {
          CustomRoleSchema.new(connector, contributor_with_mobile)
        }

        it "returns the contributor role" do
          schema.role.should == {:current=>:contributor, :capabilities=>[:comment, :kudo], :upgrades=>{}}
        end

      end

  end

end
