require './env'
require 'sinatra/base'
if ENV['RACK_ENV'] == 'production'
  require 'rpm_contrib'
  require 'newrelic_rpm'
else
  require "sinatra/reloader"
end
require './lib/all'


class Service < Sinatra::Base
  configure do |c|
    set :public, File.dirname(__FILE__) + '/public'
    set :haml, :format => :html5
    layout :layout
  end

  configure :development do |c|
    register Sinatra::Reloader
  end

  def cache_page(seconds=60*60)
    response['Cache-Control'] = "public, max-age=#{seconds}" unless :development
  end

  def fetch_and_parse_news
    url='http://fi.cs.hm.edu/fi/rest/public/news.xml'
    xml=''
    begin
      Timeout::timeout(5) do
        xml = Net::HTTP.get_response(URI.parse(url)).body
      end
    rescue
      return false, "Could not fetch data from #{url} in time. I guess thier servers are pretty slow right now. Try accessing the board directly, link is in the footer."
    end

    return true, Nokogiri::XML(xml)
  end

  def get_all_news
    success, doc = fetch_and_parse_news
    return doc.css('news').map{ |n| Hash.from_xml(n.to_s)['news']} if success
    return success, doc
  end

  def get_news(interesting_teachers)
    success, doc = fetch_and_parse_news
    if success
      by_teachers = doc.css('teacher').find_all { |node| node.text =~ interesting_teachers }
      interesting_news = by_teachers.map { |e| e.parent }

      return success, interesting_news.map{ |n| Hash.from_xml(n.to_s)['news']}
    end
    return success, doc
  end

  def get_dozent(dozent)
    return nil unless dozent

    d = DB.get("prof:#{dozent}")
    unless d.nil?
      return d
    else
      url="http://fi.cs.hm.edu/fi/rest/public/person/name/#{dozent}.xml"
      xml = Net::HTTP.get_response(URI.parse(url)).body

      p = Hash.from_xml(xml)['person']
      name = "#{p['title']} #{p['firstname']} #{p['lastname']}"
      DB.set "prof:#{dozent}", name
      DB.expire "prof:#{dozent}", 60*60*24 #delete keys after one day
      return name
    end
  end

#  def parseText(text)
#    text.delete! '#'
#    text.gsub!(/\n\s*\.\s*\n/,"\n\n")
#    text.gsub!(/\n+\s*\./,"\n\n- ")
#    RDiscount.new(text).to_html.gsub(/<li><p>(.*)<\/p><\/li>/, '<li>\1</li>')
#  end

  def markdown(text)
    text.delete! '#'
    text.gsub! /^\s*\./, ''
    options = [:hard_wrap, :filter_html, :autolink, :no_intraemphasis, :tables]
    Redcarpet.new(text, *options).to_html
  end

  get '/' do
    cache_page
    #lvh.me/?teacher=kirchulla fischermax sochergudrun koehlerklaus petersgeorg lindermeierrobert
    t = params[:teacher]
    if t && !t.empty?
      if t == '_all_'
        success, @news = get_all_news
        t = ''
      else
        success, @news = get_news(/#{t.downcase.split.join '|'}/)
      end
      if success
        @news.each do |n,i|
          #n['expire']=Time.local(*(n['expire'].split('-')))
          #n['publish']=Time.local(*(n['publish'].split('-')))
          n['text'] = markdown(n['text']) unless n['text'].nil?
        end
        #@news.map!{|n| e=Time.local(*(n['expire'].split('-'))) }
        @news.sort!{|a,b| a['expire'] <=> b['expire']}
      end
    end
    haml :news, :locals => {:teacher => t, :success => success}
  end

  get '/piwik-opt-out' do
    '<iframe frameborder="no" width="600px" height="200px" src="http://stats.eger-andreas.de/index.php?module=CoreAdminHome&action=optOut"></iframe>'
  end

  app_file = "service.rb"
  run! if app_file == $0
end
