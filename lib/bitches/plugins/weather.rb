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

      def initialize(*args)
        super

        unless config.key? :api_key
          warn "No :api_key setting found for plugin #{self.class}"
        end
      end

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

      def handle_exceptions(m, e)
        m.reply "Something went wrong."
        bot.loggers.exception e
      end

      BASE_URI = URI("http://api.wunderground.com/api/")
      
      def weather_for(location)
        location = URI.escape location
        uri = BASE_URI + "#{config[:api_key]}/conditions/q/#{location}.json"

        weather = Bonehead.insist 3 do
          open(uri) { |f| JSON.parse(f.read) }
        end

        if weather["response"].key? "error"
          return "Error from Wunderground: " + 
            weather["response"]["error"]["description"]
        elsif weather["response"].key? "results"
          places = weather["response"]["results"].map do |place|
            if place["state"].empty?
              "#{place["name"]}, #{place["country_iso3166"]}"
            else
              "#{place["name"]}, #{place["state"]}, #{place["country_iso3166"]}"
            end
          end

          return "Try again with one of these: #{places * ' | '}"
        else
          return format_weather weather["current_observation"]
        end
      end

      def format_weather(obs)
        location    = obs["display_location"]["full"]
        description = obs["weather"].capitalize
        temperature = "#{obs["temp_c"]}º C (#{obs["temp_f"]}º F)"
        wind        = "Wind: #{obs["wind_kph"]} km/h (#{obs["wind_mph"]} mph)" \
          ", #{obs["wind_dir"]}" 
        humidity    = "Humidity: #{obs["relative_humidity"]}"

        "#{location}. #{description}. #{temperature}. #{wind}. #{humidity}."
      end
    end
  end
end
