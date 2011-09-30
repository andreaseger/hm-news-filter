# A sample Gemfile
source "http://rubygems.org"

gem 'sinatra'
gem 'nokogiri'
gem 'haml'
gem 'redcarpet'
#gem 'rdiscount'

gem 'hiredis'
gem 'redis'
gem 'unicorn'

gem 'activesupport', :require => 'active_support/core_ext'
gem 'i18n'

group :production do
  gem 'newrelic_rpm'
end

group :development do
  gem 'sinatra-reloader', :require => 'sinatra/reloader'
  gem 'capistrano'
  gem 'compass'
  gem 'compass-susy-plugin'
  gem 'pry'
end
