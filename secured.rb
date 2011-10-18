class Secured < SharedSinatra
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
      session[:db_notice] = "Room data updated successfully"
    else
      session[:db_error] = data
    end
  end

  get '/' do
    update_data
    redirect '/rooms'
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
