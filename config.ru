require './env'
require 'bundler'

rack_env = ENV['RACK_ENV'] || 'production'

Bundler.setup
Bundler.require(:default, rack_env)

REDIS_CONFIG = if ENV['HM_REDIS_URL']
  require 'uri'
  uri = URI.parse ENV['HM_REDIS_URL']
  { :host => uri.host, :port => uri.port, :password => uri.password, :db => uri.path.gsub(/^\//, '') }
else
  {}
end

require './service'
run Service
