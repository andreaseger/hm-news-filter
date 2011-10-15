class News < SharedSinatra
  def get_news(teachers=nil)
    success, data = fetch_and_parse_data('http://fi.cs.hm.edu/fi/rest/public/news.xml')
    if success
      if teachers
        return  data.xpath('./newslist/news').map{ |n|
                  (n.xpath('teacher|author').children.text =~ teachers) ? n : nil
                }.compact, ''
      end
      return data.xpath('./newslist/news'), ''
    end
    return false, data
  end

  def get_dozent(dozent)
    return nil unless dozent

    d = database.get("prof:#{dozent}")
    unless d.nil?
      return d.force_encoding("UTF-8")
    else
      url="http://fi.cs.hm.edu/fi/rest/public/person/name/#{dozent}.xml"
      xml = Net::HTTP.get_response(URI.parse(url)).body

      p = Hash.from_xml(xml)['person']
      name = "#{p['title']} #{p['firstname']} #{p['lastname']}"
      database.set "prof:#{dozent}", name
      database.expire "prof:#{dozent}", 60*60*24*3 #delete keys after three day
      return name
    end
  end

  def markdown(text)
    return if text.nil?
    text.delete! '#'
    text.gsub! /^\s*\./, ''
    options = [:hard_wrap, :filter_html, :autolink, :no_intraemphasis, :tables]
    Redcarpet.new(text, *options).to_html
  end

  get '/' do
    clear_flash
    cache_page
    #lvh.me/?teacher=kirchulla fischermax sochergudrun koehlerklaus petersgeorg lindermeierrobert
    t = params[:teacher]
    if t && !t.empty?
      if t == '_all_'
        @news, message = get_news /.*/
        t = ''
      else
        @news, message = get_news(/#{t.downcase.split.join '|'}/)
      end
      if @news
        flash[:notice] = message
        @news.map! do |n|
          {
            expire: Time.local(*(n.xpath('expire').children.text.split('-'))),
            publish: Time.local(*(n.xpath('publish').children.text.split('-'))),
            text: markdown(n.xpath('text').children.text),
            subject: n.xpath('subject').children.text,
            teacher: n.xpath('teacher').map do |t|
              d=t.children.text
              { link: "http://fi.cs.hm.edu/fi/rest/public/person/name/#{d}", name: get_dozent(d) }
            end
          }
        end
        @news.sort!{|a,b| a[:publish] <=> b[:publish]}.reverse!
      else
        flash[:error] = message
      end
    end
    haml :news, locals: {teacher: t}
  end
end
