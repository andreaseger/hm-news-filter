# A sample Gemfile
source "http://rubygems.org"

gem 'sinatra', :require => 'sinatra/base'
gem 'haml'
gem 'sinatra-flash', :require => 'sinatra/flash'
gem 'redcarpet'

gem 'nokogiri'
gem 'redis'
gem 'unicorn'

gem 'activesupport', :require => 'active_support/core_ext'
gem 'i18n'

group :production do
  gem 'newrelic_rpm'
  gem 'hiredis'
end

group :development do
  gem 'sinatra-reloader', :require => 'sinatra/reloader'
  gem 'capistrano'

  gem 'compass'
  gem 'compass-susy-plugin'
  gem 'rb-inotify'
  gem 'guard-compass'
  gem 'guard-livereload'

  gem 'pry'
end
