require 'deepstruct'

module Pebblebed
  module RSpecHelper
    def god!(options = {})
      options.delete(:god)
      stub_current_identity({:id => 1, :god => true}.merge(options))
    end

    def user!(options = {})
      options.delete(:god)
      stub_current_identity({:id => 1, :god => false}.merge(options))
    end

    def guest!
      stub_current_identity
    end

    def current_identity
      @current_identity
    end

    def another_identity
      id = current_identity ? (current_identity.id + 1) : 1
      DeepStruct.wrap(deep_stringify_keys({:id => id, :god => false}.merge(default_identity_options)))
    end

    private
      def stub_current_identity(options = {})

        guest = options.empty?

        identity = nil
        unless guest
          identity = default_identity_options.merge(options)
        end

        @current_identity = DeepStruct.wrap(deep_stringify_keys(identity))

        checkpoint = stub(:get => DeepStruct.wrap(:identity => identity), :service_url => 'http://example.com')
        Pebblebed::Connector.any_instance.stub(:checkpoint => checkpoint)

        unless guest
          session = options.fetch(:session) { 'validsession' }
          stub_current_session session
        end
      end

      def default_identity_options
        {:realm => 'testrealm'}
      end

      def stub_current_session(session)
        app.any_instance.stub(:current_session).and_return session
      end

      def deep_stringify_keys(hash)
        if hash and hash.is_a?(Hash)
          hash.keys.each do |key|
            val = hash.delete(key)
            hash[key.to_s] = val.is_a?(Hash) ? val.deep_stringify_keys(val) : val
          end
        end
        hash
      end

  end
end

