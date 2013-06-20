# encoding: utf-8

require 'retryable'
require 'yahoo_weatherman'

module Cinch
  module Plugins
    class Weather
      include Cinch::Plugin
      include Retryable

      NoWeather = Class.new StandardError

      # TODO: Find a decent Yahoo! Weather API wrapper.
      set :plugin_name, 'weather'
      set :help, 'Usage: !weather [<location>].'

      match /weather(?: (.+))?/s, method: :weather

      def initialize(*args)
        super

        @client = Weatherman::Client.new :unit => 'C'
      end

      def weather(m, location = nil)
        user = Models::User.find_user m.user.authname || m.user.nick
        user.update :location => location unless location.nil?

        retryable do
          if location.nil? && user.location.nil?
            raise NoWeather, "Tell me where you are first (!weather location)" +
              ", I'll remember after that."
          end

          weather = @client.lookup_by_location location || user.location

          # Weatherman doesn't have an error response. Dirrrrrty.
          unless weather.location.is_a? Nokogiri::XML::Element
            raise NoWeather, "Could not find the weather for \"#{location}\"."
          end

          if weather.location['country'] == 'United States'
            loc = "#{weather.location['city']}, #{weather.location['region']}"
          else
            loc = "#{weather.location['city']}, #{weather.location['country']}"
          end

          condition = weather.condition['text']
          temp      = "#{weather.condition['temp']}º C (" +
            "#{to_f weather.condition['temp']}º F)"
          wind      = "Wind: #{Float(weather.wind['speed']).ceil} " +
            "#{weather.units['speed']} (#{(Float(weather.wind['speed']) * 
            0.621371192).ceil} mph), #{direction weather.wind['direction']}"
          humidity  = "Humidity: #{Float(weather.atmosphere['humidity']).ceil}%"

          fc        = weather.forecasts.first
          tomorrow  = "#{fc['text']}, #{fc['low']}-#{fc['high']}º C (" +
            "#{to_f fc['low']}-#{to_f fc['high']}º F)"

          m.reply "#{loc}: #{condition}, #{temp}. #{wind}. #{humidity}. " +
            "Tomorrow: #{tomorrow}."
        end
      rescue NoWeather => e
        m.reply e.message
      rescue => e 
        bot.loggers.error e.message
        bot.loggers.error e.backtrace
        m.reply "Something went wrong."
      end

    private

      def direction(degrees)
        directions = { 
          348.75..11.25  => 'North',      11.25..33.75   => 'North North-East', 
          33.75..56.25   => 'North-East', 56.25..78.75   => 'East North-East',
          78.75..101.25  => 'East',       101.25..123.75 => 'East South-East',
          123.75..146.25 => 'South-East', 146.25..168.75 => 'South South-East',
          168.75..191.25 => 'South',      191.25..213.75 => 'South South-West',
          213.75..236.25 => 'South-West', 236.25..258.75 => 'West South-West',
          258.75..281.25 => 'West',       281.25..303.75 => 'West North-West',
          303.75..326.25 => 'North-West', 326.25..348.75 => 'North North-West'
        }

        dir = directions.find { |range, direction| range.include? degrees }

        return dir.nil? ? 'None' : dir.last
      end

      def to_f(temp)
        (Float(temp) * 1.8 + 31).ceil
      end
    end
  end
end
