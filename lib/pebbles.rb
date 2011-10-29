require "pebbles/version"
require 'pebbles/pow_proxy'
require 'pebbles/http'
require 'pebbles/session'
require 'pebbles/generic_client'
require 'pebbles/identity'

module Pebbles
  def self.config(params)
    @host = params[:host]
    @redis = Redis.new(params[:redis]) if params[:redis]
    @services = params[:services]
  end

  def self.host
    @host || 'pebbles.dev'
  end

  def self.redis
    @redis
  end

  def self.version_of(service)
    return 1 unless @services && @services[service.to_sym]
    @services[service.to_sym][:version] || 1
  end

  def self.root_url_for(service)
    "http://#{host}/api/#{service}/v#{version_of(service)}/"
  end
end
