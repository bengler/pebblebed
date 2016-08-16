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
    role :contributor, :capabilities => [:comment], :requirements => [:logged_in, :verified_mobile]

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
      expect(schema.connector).to eq connector
      expect(schema.identity).to eq guest
    end

    it "has the correct roles defined" do
      expect(CustomRoleSchema.roles).to eq([{:capabilities=>[], :requirements=>[], :name=>:guest, :role_rank=>0, :upgrades=>{:kudo=>[:logged_in], :comment=>[:logged_in, :verified_mobile]}}, {:capabilities=>[:kudo], :requirements=>[:logged_in], :name=>:identified, :role_rank=>1}, {:capabilities=>[:comment], :requirements=>[:logged_in, :verified_mobile], :name=>:contributor, :role_rank=>2}])
    end

    it "has an answer to requirements for a role" do
      expect(CustomRoleSchema.requirements_for_role(:identified)).to eq([:logged_in])
      expect(CustomRoleSchema.requirements_for_role(:contributor)).to eq([:logged_in, :verified_mobile])
    end

    it "gives a exception when the role is not found" do
      expect {
        CustomRoleSchema.requirements_for_role(:foo)
      }.to raise_error(Pebblebed::Security::RoleSchema::UndefinedRole)
    end

  end

  context "as guest" do

    let(:schema) {
      CustomRoleSchema.new(connector, guest)
    }

    it "returns the guest role" do
      expect(schema.role).to eq({:current=>:guest, :capabilities=>[], :upgrades=>{:kudo=>[:logged_in], :comment=>[:logged_in, :verified_mobile]}})
    end

  end

  context "as contributor" do

      context "with a contributor without verified mobile" do

        let(:schema) {
          CustomRoleSchema.new(connector, contributor)
        }

        it "returns the idenitified role with an upgrade for :verified_mobile only" do
          expect(schema.role).to eq({:current=>:identified, :capabilities=>[:kudo], :upgrades=>{:comment=>[:verified_mobile]}})
        end

      end

      context "with a contributor with a verified mobile" do

        let(:schema) {
          CustomRoleSchema.new(connector, contributor_with_mobile)
        }

        it "returns the contributor role" do
          expect(schema.role).to eq({:current=>:contributor, :capabilities=>[:kudo, :comment], :upgrades=>{}})
        end

      end

  end

end
