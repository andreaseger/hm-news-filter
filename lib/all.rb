require 'net/http'
require 'nokogiri'
require 'haml'
require 'rdiscount'
require 'iconv'

require 'hiredis'
require 'redis'

require 'active_support/core_ext'

redis_config = if ENV['HM_REDIS_URL']
  require 'uri'
  uri = URI.parse ENV['HM_REDIS_URL']
  { :host => uri.host, :port => uri.port, :password => uri.password, :db => uri.path.gsub(/^\//, '') }
else
  {}
end

DB = Redis.new(redis_config)
