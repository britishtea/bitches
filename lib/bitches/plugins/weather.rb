# Encoding: utf-8
require "bonehead"
require "json"
require "open-uri"

module Bitches
  module Plugins
    class Weather
      include Cinch::Plugin

      AmbiguousQuery = Class.new(ArgumentError)
      NoResults      = Class.new(ArgumentError)

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
        user = Models::User.by_nickname(m.user.authname || m.user.nick)

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
        user = Models::User.by_nickname(m.user.authname || m.user.nick)
        user.location = location
        user.save

        m.reply weather_for(user.location)
      rescue => e
        handle_exceptions m, e     
      end

    private

      def handle_exceptions(m, e)
        case e
          when NoResults      then msg = "Error from Wunderground: #{e.message}"
          when AmbiguousQuery then msg = e.message
          else                     msg = "Something went wrong."
        end

        m.reply(msg)
        bot.loggers.exception e
      end

      BASE_URI = URI("http://api.wunderground.com/api/")
      
      # Raises NoResults if no place was found.
      # Raises AmbiguousQuery if more than one places were found.
      def weather_for(location)
        location = URI.escape location
        uri = BASE_URI + "#{config[:api_key]}/conditions/q/#{location}.json"

        weather = Bonehead.insist 3 do
          open(uri) { |f| JSON.parse(f.read) }
        end

        response = weather["response"]

        if response.key?("error")
          raise NoResults, response["error"]["description"]
        elsif response.key?("results")
          raise AmbiguousQuery, suggested_queries(response["results"])
        end

        return format_weather(weather["current_observation"])
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

      def suggested_queries(results)
        places = results.map do |place|
          if place["state"].empty?
            "#{place["name"]}, #{place["country_name"]}"
          else
            "#{place["name"]}, #{place["state"]}, #{place["country_iso3166"]}"
          end
        end

        return "Try again with one of these: #{places * ' | '}"
      end
    end
  end
end
