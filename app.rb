require 'json'

require 'iron_cache'
require 'sendgrid-ruby'
require 'sinatra/base'
require 'wunderground'

# Create a modular style Sinatra app
class FourMom < Sinatra::Base
  # Create a new SendGrid client
  @@sg = SendGrid::Client.new do |c|
    c.api_user = ENV['SENDGRID_USERNAME']
    c.api_key  = ENV['SENDGRID_PASSWORD']
  end

  # Grab our Iron Cache
  @@cache = IronCache::Client.new.cache('fourmom')

  # Set up Wunderground
  @@w_api = Wunderground.new(ENV['WUNDERGROUND_API_KEY'])

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
    zip     = checkin['venue']['location']['postalCode']

    # Check if we are somewhere new
    if city != @@city || state != @@state
      # Update our values
      @@city = city
      @@state = state
      @@cache.put('city', @@city)
      @@cache.put('state', @@state)

      # Grab the weather
      res     = @@w_api.conditions_for(zip)
      weather = res["current_observation"]["weather"]
      temp    = res["current_observation"]["temp_f"]

      # Create a new email...
      mail = SendGrid::Mail.new do |m|
        m.to      = ENV['PHONE_NUMBER']
        m.from    = 'taco@cat.limo'
        m.subject = 'FourMom'
        m.text    = "Hi mama! I'm currently in: #{city}, #{state}. It's currently #{temp} and #{weather}"
      end

      # ... and send it!
      @@sg.send(mail)
    end
  end
end

