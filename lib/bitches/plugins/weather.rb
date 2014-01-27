# Encoding: utf-8
require "bonehead"
require "json"
require "open-uri"

module Bitches
  module Plugins
    class Weather
      include Cinch::Plugin

      # TODO: Forecasts.

      set :plugin_name, "weather"
      set :help, "Usage: !weather [<location>]."

      match /weather$/s,     :group => :weather, :method => :cached_location
      match /weather (.+)/s, :group => :weather, :method => :change_location

      def cached_location(m)
        user = Models::User.find_user m.user.authname || m.user.nick

        if user.location.nil?
          m.reply "Tell me where you are first (!weather location), I'll " \
          "remember after that."
        else
          m.reply weather_for user.location
        end
      rescue => e
        handle_exceptions m, e
      end

      def change_location(m, location)
        user = Models::User.find_user m.user.authname || m.user.nick
        user.update :location => location

        m.reply weather_for user.location
      rescue => e
        handle_exceptions m, e     
      end

    private

      BASE_URI = URI("http://api.openweathermap.org/data/2.5").tap do |u|
        u.query = URI.encode_www_form :units => "metric"
      end

      DIRECTIONS = { 
        348.75...11.25  => 'North',      11.25..33.75   => 'North North-East', 
        33.75...56.25   => 'North-East', 56.25..78.75   => 'East North-East',
        78.75...101.25  => 'East',       101.25..123.75 => 'East South-East',
        123.75...146.25 => 'South-East', 146.25..168.75 => 'South South-East',
        168.75...191.25 => 'South',      191.25..213.75 => 'South South-West',
        213.75...236.25 => 'South-West', 236.25..258.75 => 'West South-West',
        258.75...281.25 => 'West',       281.25..303.75 => 'West North-West',
        303.75...326.25 => 'North-West', 326.25..348.75 => 'North North-West'
      }

      def handle_exceptions(m, e)
        m.reply "Something went wrong."
        bot.loggers.exception e
      end
      
      def weather_for(location)
        uri       = BASE_URI.dup
        uri.path += "/weather"
        uri.query = URI.encode_www_form q: location, units: "metric"

        weather = Bonehead.insist 3 do
          open(uri) { |f| JSON.parse f.read }
        end

        return weather["message"] unless weather["cod"] == 200

        location    = "#{weather["name"]}, #{weather["sys"]["country"]}"
        description = "#{weather["weather"].first["main"]}, " \
          "#{weather["weather"].first["description"]}"
        temperature = "#{Integer(weather["main"]["temp"]).ceil}º C " \
          "(#{fahrenheit weather["main"]["temp"]}º F)"
        wind        = "Wind: #{Integer(weather["wind"]["speed"]).ceil} km/h " \
          "(#{miles weather["wind"]["speed"]} mph), " \
          "#{direction weather["wind"]["deg"]}" 
        humidity    = "Humidity: #{weather["main"]["humidity"]}%"

        "#{location}: #{description}. #{temperature}. #{wind}, #{humidity}."
      end

      def fahrenheit(celcius)
        (celcius * 1.8 + 31).ceil
      end

      def miles(kilometers)
        (kilometers * 0.621371192).ceil
      end

      def direction(degrees)
        DIRECTIONS.find { |range, direction| range.include? degrees.to_i }.last
      end
    end
  end
end
