require 'rubygems'
require 'env'
require 'rpm_contrib'
require 'newrelic_rpm'
require 'sinatra/base'
require "sinatra/reloader" unless ENV['RACK_ENV'] == 'production'
require 'lib/all'

class Service < Sinatra::Base
  configure do |c|
    set :public, File.dirname(__FILE__) + '/public'
    set :haml, :format => :html5
    layout :layout
  end

  configure :development do |c|
    register Sinatra::Reloader
  end

  def ic
    @ic ||= Iconv.new('UTF-8','iso-8859-1')
  end

  def get_news(interesting_teachers)
    url='http://sol.cs.hm.edu/fi/rest/public/news.xml'
    xml = Net::HTTP.get_response(URI.parse(url)).body

    doc = Nokogiri::XML(ic.iconv(xml))#.force_encoding('iso-8859-1').encode('utf-8'))
    by_teachers = doc.css('teacher').find_all { |node| node.text =~ interesting_teachers }
    interesting_news = by_teachers.map { |e| e.parent }

    news = interesting_news.map{ |n| Hash.from_xml(n.to_s)['news']}
  end

  def get_dozent(dozent)
    return nil unless dozent
    d = DB.get("prof:#{dozent}")
    unless d.nil?
      return d
    else
      url="http://sol.cs.hm.edu/fi/rest/public/person/name/#{dozent}.xml"
      xml = Net::HTTP.get_response(URI.parse(url)).body
      p = Hash.from_xml(ic.iconv(xml))['person']
      name = "#{p['title']} #{p['firstname']} #{p['lastname']}"
      DB.set "prof:#{dozent}", name
      DB.expire "prof:#{dozent}", 60*60*24 #delete keys after one day
      name
    end
  end

  get '/' do
    #lvh.me/?teacher=kirchulla fischermax sochergudrun koehlerklaus petersgeorg lindermeierrobert
    t = params[:teacher]
    if t && !t.empty?
      @news = get_news(/#{t.split.join '|'}/)
    end
    haml :news, :locals => {:teacher => params[:teacher]}
  end

  app_file = "service.rb"
  run! if app_file == $0
end
