class Mensa < SharedSinatra

  def get_food(mensa_id)
    #TODO get the current or next availabe week day for the url
    url = "http://www.studentenwerk-muenchen.de/mensa/speiseplan/speiseplan_2011-10-17_#{mensa_id}_-de.html"
    s, data = fetch_and_parse_data(url)
    if s
      d=data.xpath('//table[@class="menu"]').first.xpath('//tr/td/span').map {|s| s.content.strip }
      d.delete_at 0       #wierd empty element
      date = d.delete_at(0).split[0..1].join(' ')
      d.delete_at 0       #PDF element
      f=[]
      d.each_slice(2){|e| f << {name: e[0], meatless: (e[1] =~ /fleischlos/) == 1 } }

      return {food: f, pdflink: url.gsub(/\.html/,'.pdf')}, ''
    end
    return nil, data
  end

  get '/' do
    clear_flash
    cache_page
    search = params[:search] || ""
    logger.info "mensa: #{search}"
    unless search.empty?
      @mensa, message = get_food search
    end
    if @mensa
      flash[:notice] = message
    else
      flash[:error] = message
    end

    haml :mensa, locals: {search: search, current: :mensa}
  end
end
