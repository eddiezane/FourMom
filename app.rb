require 'json'

require 'iron_cache'
require 'sendgrid-ruby'
require 'sinatra/base'

# Create a modular style Sinatra app
class FourMom < Sinatra::Base
  # Create a new SendGrid client
  @@sg = SendGrid::Client.new do |c|
    c.api_user = ENV['SENDGRID_USERNAME']
    c.api_key  = ENV['SENDGRID_PASSWORD']
  end

  # Grab our Iron Cache
  @@cache = IronCache::Client.new.cache('fourmom')

  # Save the values locally in case our dyno went to sleep
  @@city  = @@cache.get('city')
  @@city  = @@city.value if @@city
  @@state = @@cache.get('state')
  @@state = @@state.value if @@state

  # Our post request handler
  post '/' do
    # Parse out the data from Foursquare
    checkin = JSON.parse(params[:checkin])
    city    = checkin['venue']['location']['city']
    state   = checkin['venue']['location']['state']

    # Check if we are somewhere new
    if city != @@city || state != @@state
      # Update our values
      @@city = city
      @@state = state
      @@cache.put('city', @@city)
      @@cache.put('state', @@state)

      # Create a new email...
      mail = SendGrid::Mail.new do |m|
        m.to      = '1238675309@vtext.com'
        m.from    = 'taco@cat.limo'
        m.subject = 'FourMom'
        m.text    = "Hi mama! I'm currently in: #{city}, #{state}."
      end

      # ... and send it!
      @@sg.send(mail)
    end
  end
end

