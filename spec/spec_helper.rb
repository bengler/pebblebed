require 'simplecov'
require './spec/mockcached'
require './spec/mock_pebble'
require 'bundler'
require 'rspec'

SimpleCov.add_filter 'spec'
SimpleCov.add_filter 'config'
SimpleCov.start

Bundler.require

RSpec.configure do |c|
  c.mock_with :rspec
  c.around(:each) do |example|
    clear_cookies if respond_to?(:clear_cookies)
    $memcached = Mockcached.new
    example.run
  end
end
