require 'simplecov'
require 'rspec'

SimpleCov.add_filter 'spec'
SimpleCov.add_filter 'config'
SimpleCov.start

require 'yajl/json_gem'
require 'deepstruct'

require 'memcache_mock'
require './spec/mock_pebble'

Dir.glob(File.expand_path('../helpers/*.rb', __FILE__)).each(&method(:require))

require_relative '../lib/pebblebed/config'

RSpec.configure do |c|
  c.mock_with :rspec
  c.include MockPebbleHelper

  c.before(:each) do
    ::Pebblebed.memcached = MemcacheMock.new
  end

  c.around(:each) do |example|
    clear_cookies if respond_to?(:clear_cookies)
    example.run
  end

  c.before :all do
    # Starts the mock pebble at localhost:8666/api/mock/v1
    mock_pebble
  end
end
