require 'simplecov'
require 'rspec'

SimpleCov.add_filter 'spec'
SimpleCov.add_filter 'config'
SimpleCov.start

require 'memcache_mock'
require './spec/mock_pebble'

RSpec.configure do |c|
  c.mock_with :rspec
  c.around(:each) do |example|
    clear_cookies if respond_to?(:clear_cookies)
    $memcached = MemcacheMock.new
    example.run
  end
end
