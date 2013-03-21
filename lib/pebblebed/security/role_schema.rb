module Pebblebed
  module Security
    class RoleSchema

      attr_reader :connector, :identity, :policy

      class << self
        attr_reader :roles
      end

      def initialize(connector, identity, policy=nil)
        @connector = connector
        @identity = identity
        @policy = policy
      end

      def role
        @role ||= find_current_role
        {
          :current => @role[:name],
          :capabilities => @role[:capabilities],
          :upgrades => @role[:upgrades]
        }
      end

      def find_current_role
        the_role = begin
          collected_roles = []
          self.class.roles.each do |role|
            collected_capabilities = []
            if role[:requirements].any?
              role[:requirements].each do |requirement|
                # Special exceptions based on the optional policy
                if policy and requirement == :verified_mobile and !policy.require_verified_mobile
                  collected_capabilities << requirement
                elsif policy and requirement == :verified_name and !policy.require_verified_name
                  collected_capabilities << requirement
                # Regular check based on implemented check-methods
                else
                  begin
                    if __send__("check_#{requirement}".to_sym)
                      collected_capabilities << requirement
                    end
                  rescue NoMethodError
                    raise NoMethodError, "You must implement method named :check_#{requirement} that returns true or false"
                  end
                end
              end
              if (role[:requirements] & collected_capabilities) == role[:requirements]
                the_role = role
                collected_roles << role
              end
            else
              the_role = role
              collected_roles << role
            end
          end
          the_role.merge(:upgrades => begin
              result = {}
              (self.class.roles - collected_roles).each{|r|
                result[:"#{r[:name]}"] = r[:requirements]
              }
              result
            end
          )
        end
      end

      def self.role(name, options)
        @roles ||= []
        @role_rank_level ||= 0
        @roles << options.merge(:name => name, :role_rank => @role_rank_level)
        @roles.sort!{|a,b| a[:role_rank] <=> b[:role_rank]}
        @role_rank_level += 1
      end

    end
  end
end
