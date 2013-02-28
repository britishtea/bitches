# encoding: utf-8

require 'yahoo_weatherman'

module Cinch
  module Plugins
    class Weather
      include Cinch::Plugin

      # TODO: Find a decent Yahoo! Weather API wrapper.
      set :plugin_name, 'weather'
      set :help, 'Usage: !weather [<location>].'

      match /weather(?: (.+))?/s, method: :weather

      def initialize(*args)
        super

        @client = Weatherman::Client.new :unit => 'C'
      end

      def weather(m, location = nil)
        user = Models::User.first_or_create(
          :nickname => m.user.authname || m.user.nick
        )
        user.update :location => location unless location.nil?

        weather = @client.lookup_by_location location || user.location

        # Weatherman doesn't have an error response. Dirrrrrty.
        unless weather.location.is_a? Nokogiri::XML::Element
          m.reply "Could not find the weather for #{location}."
          return
        end

        if weather.location['country'] == 'United States'
          loc = "#{weather.location['city']}, #{weather.location['region']}"
        else
          loc = "#{weather.location['city']}, #{weather.location['country']}"
        end

        condition = weather.condition['text']
        temp      = "#{weather.condition['temp']}º C (" +
          "#{Integer(weather.condition['temp']) * 1.8 + 32}º F)"
        wind      = "Wind: #{weather.wind['speed']} #{weather.units['speed']}" +
          ", #{wind_direction_name weather.wind['direction']}"
        humidity  = "Humidity: #{Float(weather.atmosphere['humidity']).ceil}%"

        fc  = weather.forecasts.first
        tomorrow  = "#{fc['text']}, #{fc['low']}-#{fc['high']}º C (" +
          "#{fc['low'] * 1.8 + 32}-#{fc['high'] * 1.8 + 32}º F)"

        m.reply "#{loc}: #{condition}, #{temp}. #{wind}. #{humidity}. " +
          "Tomorrow: #{tomorrow}."
      end

    private

      def wind_direction_name(degrees)
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

        directions.find { |range, direction| range.include? degrees }.last
      end
    end
  end
end