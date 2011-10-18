require_relative 'lib/helper'
require 'net/http'
require 'json'

class SharedSinatra < Sinatra::Base
  configure do |c|
    helpers Sinatra::MyHelper

    set :public_folder, File.dirname(__FILE__) + '/public'
    set :haml, :format => :html5

    enable :sessions
    use Rack::Flash

    layout :layout
  end

  configure :development do |c|
    register Sinatra::Reloader
    c.also_reload "./lib/**/*.rb"
  end

  def database
    @database ||= Redis.new(REDIS_CONFIG)
  end

  def fetch_and_parse_data(url)
    xml=''
    begin
      Timeout::timeout(5) do
        net = Net::HTTP.get_response(URI.parse(url))
        return false, "HTTP Error: #{net.code}" if %w(404 500).include? net.code
        xml = net.body
      end
    rescue
      logger.error "Could not fetch data from #{url}"
      return false, "Could not fetch data from #{url} in time. I guess thier servers are pretty slow right now. Try accessing the board directly, link is in the footer."
    end

    if url =~ /\.html/
      return true, Nokogiri::HTML(xml)
    end
    return true, Nokogiri::XML(xml)
  end
end

class Default < SharedSinatra
  get '/' do
    redirect '/news'
  end
end

require_relative 'news'
require_relative 'rooms'
require_relative 'secured'
require_relative 'mensa'
