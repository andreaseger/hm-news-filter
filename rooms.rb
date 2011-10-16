class Rooms < SharedSinatra

  def save_to_database(xml)
    #delete all old data before saving the new one
    database.flushdb
    logger.info "deleted all data from the database"

    data=xml.xpath('./list/timetable').map do |t|
      room = t.xpath('value').children.text
      next if room.empty?
      bookings = t.xpath('day/time/booking').map { |b| [ b.xpath('weekday').children.text, b.xpath('starttime').children.text] }
      { name: room,
        floor: room[1].to_i,
        building: room[0],
        bookings: bookings
      }
    end

    data.compact.each do |room|
        if room[:bookings]
          room[:bookings].each do |booking|
            #TODO find a nicer format for the timeslots
            database.sadd "rooms:#{room[:name]}", booking.to_json
            database.sadd "rooms:#{booking.to_json}", room[:name]
          end
        end

        database.sadd "rooms:#{room[:building]}", room[:name]
        database.sadd "rooms:#{room[:building]}#{room[:floor]}", room[:name]
    end
  end

  def update_data
    s, data = fetch_and_parse_data('http://fi.cs.hm.edu/fi/rest/public/timetable/room.xml')
    if s
      save_to_database(data)
      flash[:db_notice] = "Room data updated successfully"
    else
      flash[:db_error] = data
    end
  end

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
      room unless database.smembers("rooms:#{room}", timeslot.to_json)
    end

    return rooms, "Rooms for Timeslot: #{timeslot.join(' ')} | Building: #{building} | Floor: #{floor}"
  end

  get '/' do
    clear_flash
    flash[:notice] = flash[:db_notice]
    flash[:error] = flash[:db_error]
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

  get '/update' do
    update_data
    redirect to('/')
  end

  def self.new(*)
    app = Rack::Auth::Digest::MD5.new(super) do |username|
      {'sch1zo' => ENV['HM_ROOMS_SECRET']}[username]
    end
    app.realm = 'Room Search'
    app.opaque = 'secretkey'
    app
  end
end
