class Rooms < SharedSinatra

  def get_current_timeslot
    time = Time.now
    w = %w(so mo di mi do fr sa)[time.strftime('%w').to_i]
    return nil if %w(so sa).include? w
    slot = case time.strftime('%H%M').to_i
           when 800..945
             "8:15"
           when 945..1130
             "10:00"
           when 1130..1315
             "11:45"
           when 1315..1500
             "13:30"
           when 1500..1645
             "15:15"
           when 1645..1830
             "17:00"
           else
             false
           end
    return nil unless slot
    [w,slot]
  end

  def get_rooms(building, floor=nil)
    timeslot = get_current_timeslot
    return false, "only works monday-friday between 8:00 and 18:30" unless timeslot
    filter_rooms = if floor
                     database.smembers "rooms:#{building}#{floor}"
                   else
                     database.smembers "rooms:#{building}"
                   end
    rooms = filter_rooms.map do |room|
      room unless database.sismember("rooms:#{room}", timeslot.to_json)
    end

    return rooms.compact, "Rooms for Timeslot: #{timeslot.join(' ')} | Building: #{building} | Floor: #{floor}"
  end

  get '/' do
    clear_flash
    if session.has_key?(:db_notice) || session.has_key?(:db_error)
      flash[:notice] = session[:db_notice]
      flash[:error] = session[:db_error]
      [:db_notice, :db_error].each {|s| session.delete(s)}
    end
    cache_page
    search = params[:search] || ""
    building, floor = search.split '-'
    logger.info "building: #{building} | floor: #{floor}"
    unless building.nil? || building.empty?
      @rooms, message = get_rooms building, floor
    end

    if @rooms
      flash[:notice] = message
    else
      flash[:error] = message
    end

    haml :room, locals: {search: search, current: :rooms }
  end

end
