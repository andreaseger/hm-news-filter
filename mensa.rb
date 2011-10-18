class Mensa < SharedSinatra

  def get_next_date
    date = Date.today
    if date.saturday?
      date = date + 1
    end
    if date.sunday?
      date = date + 1
    end

    date.strftime '%Y-%m-%d'
  end

  def get_food(mensa_id)
    url = "http://www.studentenwerk-muenchen.de/mensa/speiseplan/speiseplan_#{get_next_date}_#{mensa_id}_-de.html"
    s, data = fetch_and_parse_data(url)
    if s
      food = data.xpath('//table[@class="menu"]//tr').map{|e| e.content.strip.split(/[\r\t\n]+/) }
      food.delete_at 0
      zusatzstoffe = data.xpath('//table[@class="zusatzstoffe"]//tr').map{|a| a.content.strip.split("\r\n").map{|e| e.strip} }
      heading = data.xpath('//div[@id="pagetitle"]').first.content

      return {mensa_name: heading, food: food, zusatzstoffe: zusatzstoffe}, ''
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
