module Pebblebed
  module Security
    class RoleSchema

      attr_reader :connector, :identity

      class << self
        attr_reader :roles
      end

      def initialize(connector, identity)
        @connector = connector
        @identity = identity
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
          capabilities = []
          self.class.roles.each do |role|
            if role[:requirements].any?
              role[:requirements].each do |requirement|
                begin
                  if self.__send__("check_#{requirement}".to_sym)
                    the_role = role
                    capabilities << role
                  end
                rescue NoMethodError
                  raise NoMethodError, "You must implement method named :check_#{requirement} that returns true or false"
                end
              end
            else
              the_role = role
              capabilities << role
            end
          end
          the_role.merge(:upgrades => begin
              result = {}
              (self.class.roles - capabilities).each{|r|
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
