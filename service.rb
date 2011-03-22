require 'rubygems'
require 'sinatra/base'
require "sinatra/reloader"# unless :production
require 'net/http'
require 'nokogiri'
require 'haml'
require 'rdiscount'

require 'ap'

class Service < Sinatra::Base
  configure do |c|
    set :public, File.dirname(__FILE__) + '/public'
    set :haml, :format => :html5
    layout :layout
  end

  configure :development do |c|
    register Sinatra::Reloader
  end


  def get_news(interesting_teachers)
    url='http://sol.cs.hm.edu/fi/rest/public/news.xml'
    xml = Net::HTTP.get_response(URI.parse(url)).body
    doc = Nokogiri::XML(xml.force_encoding('iso-8859-1').encode('utf-8'))
    teachers = doc.css 'teacher'
    by_interesting_teachers = teachers.find_all { |node| node.text =~ interesting_teachers }
    interesting_news = by_interesting_teachers.map { |e| e.parent }

    news = interesting_news.map{ |n|
      {:subject => n.at_css('subject').to_str,
       :text =>  n.at_css('text').to_str,
       :teacher =>  n.at_css('teacher').to_str
      }
    }
  end

  def get_dozent(dozent)
    url="http://sol.cs.hm.edu/fi/rest/public/person/name/#{dozent}.xml"
    xml = Net::HTTP.get_response(URI.parse(url)).body
    doc = Nokogiri::XML(xml.force_encoding('iso-8859-1').encode('utf-8'))
    "#{doc.at_css('title').to_str} #{doc.at_css('firstname').to_str} #{doc.at_css('lastname').to_str}"
  end

  get '/' do
    #lvh.me/?teacher=kirchulla fischermax sochergudrun koehlerklaus petersgeorg lindermeierrobert
    t = params[:teacher]
    @news = get_news /#{t.split.join '|'}/
    haml :news
  end

  app_file = "service.rb"
  run! if app_file == $0
end
