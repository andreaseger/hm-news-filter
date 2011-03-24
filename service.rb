require 'rubygems'
require 'env'
require 'sinatra/base'
require "sinatra/reloader" unless ENV['RACK_ENV'] == 'production'
require 'rpm_contrib' if ENV['RACK_ENV'] == 'production'
require 'newrelic_rpm' if ENV['RACK_ENV'] == 'production'
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

  def cache_page(seconds=30*60)
    response['Cache-Control'] = "public, max-age=#{seconds}" unless :development
  end

  def ic
    @ic ||= Iconv.new('UTF-8','iso-8859-1')
  end

  def fetch_and_parse_news
    url='http://sol.cs.hm.edu/fi/rest/public/news.xml'
    xml = Net::HTTP.get_response(URI.parse(url)).body

    Nokogiri::XML(ic.iconv(xml))#.force_encoding('iso-8859-1').encode('utf-8'))
  end

  def get_all_news
    doc = fetch_and_parse_news
    doc.css('news').map{ |n| Hash.from_xml(n.to_s)['news']}
  end

  def get_news(interesting_teachers)
    doc = fetch_and_parse_news
    by_teachers = doc.css('teacher').find_all { |node| node.text =~ interesting_teachers }
    interesting_news = by_teachers.map { |e| e.parent }

    interesting_news.map{ |n| Hash.from_xml(n.to_s)['news']}
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

  def parseText(text)
    text.gsub!(/#/,"")
    text.gsub!(/\n\s*\.\s*\n/,"\n\n")
    text.gsub!(/\n+\s*\./,"\n\n- ")
    RDiscount.new(text).to_html.gsub(/<li><p>(.*)<\/p><\/li>/, '<li>\1</li>')
  end

  get '/' do
    cache_page
    #lvh.me/?teacher=kirchulla fischermax sochergudrun koehlerklaus petersgeorg lindermeierrobert
    t = params[:teacher]
    if t && !t.empty?
      if t == '_all_'
        @news = get_all_news
        t = ''
      else
        @news = get_news(/#{t.downcase.split.join '|'}/)
      end
      @news.each_with_index do |n,i|
        n['expire']=Time.local(*(n['expire'].split('-')))
        n['publish']=Time.local(*(n['publish'].split('-')))
        #n['text'] = RDiscount.new(parseText(n['text'])).to_html.gsub(/<li><p>(.*)<\/p><\/li>/, '<li>\1</li>') unless n['text'].nil?
        n['text'] = parseText(n['text']) unless n['text'].nil?
      end
      #@news.map!{|n| e=Time.local(*(n['expire'].split('-'))) }
      @news.sort!{|a,b| a['expire'] <=> b['expire']}
    end
    haml :news, :locals => {:teacher => t}
  end

  app_file = "service.rb"
  run! if app_file == $0
end
