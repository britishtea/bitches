# encoding: utf-8
require "cinch"
require "bitches/models"

module Bitches
  def self.start!(server, port)
    Bot.new(server, port).start
  end

  def self.stop!(pid)
    Process.kill "SIGTERM", pid
  end

  class Bot
    VERSION = "0.1.0"

    def initialize(server, port)
      @bot = Cinch::Bot.new do
        configure do |c|
          c.server   = server
          c.port     = port
          c.password = ENV["PASSWORD"]
          c.nick     = ENV["NICKNAME"]
          c.user     = ENV["NICKNAME"]
          c.channels = ENV["CHANNELS"].split(",") << ENV["MONITOR_CHANNEL"]
          c.ssl.use  = true if ENV["SSL"] == "true"


          require "cinch/extensions/authentication"

          c.authentication = Cinch::Configuration::Authentication.new
          c.authentication.strategy = :channel_status
          c.authentication.level    = :h
          c.authentication.channel  = ENV["AUTH_CHANNEL"]

          # require "bitches/plugins/big_brother"

          # c.plugins.plugins << Bitches::Plugins::BigBrother
          # c.plugins.options[Bitches::Plugins::BigBrother] = {
          #   :channel => ENV["MONITOR_CHANNEL"]
          # }


          # require "cinch/plugins/identify"

          # c.plugins.plugins << Cinch::Plugins::Identify
          # c.plugins.options[Cinch::Plugins::Identify] = {
          #   :password => ENV["NICKSERV_PASSWORD"] || "",
          #   :type     => :nickserv
          # }


          # require "bitches/plugins/lastfm"

          # c.plugins.plugins << Bitches::Plugins::LastFM
          # c.plugins.options[Bitches::Plugins::LastFM] = {
          #   :api_key    => ENV["LASTFM_KEY"],
          #   :api_secret => ENV["LASTFM_SECRET"]
          # }


          # require "bitches/plugins/links"

          # c.plugins.plugins << Bitches::Plugins::Links


          # require "bitches/plugins/media"

          # c.plugins.plugins << Bitches::Plugins::Media
          # c.plugins.options[Bitches::Plugins::Media] = {
          #   :url           => ENV["GALLERY_URL"],
          #   :secret        => ENV["GALLERY_SECRET"],
          #   :channels      => [ENV["CHANNELS"].split(",")],
          #   :ignored_hosts => ["https://fbcdn-sphotos-c-a.akamaihd.net/"],
          #   :ignored_tags  => [/nsfw/i, /nsfl/i, /ignore/i]
          # }


          # require "cinch/plugins/preview"
          # require "cinch/plugins/preview/title"
          # require "cinch/plugins/preview/youtube"

          # c.plugins.plugins << Cinch::Plugins::Preview


          # require "bitches/plugins/recommend"

          # c.plugins.plugins << Cinch::Plugins::Recommend


          # require "cinch/plugins/search"

          # c.plugins.plugins << Cinch::Plugins::Search


          # require "cinch/plugins/slang"

          # c.plugins.plugins << Cinch::Plugins::Slang


          # require "bitches/plugins/weather"

          # c.plugins.plugins << Bitches::Plugins::Weather


          # require "bitches/plugins/whatcd"

          # c.plugins.plugins << Bitches::Plugins::WhatCD
          # c.plugins.options[Bitches::Plugins::WhatCD] = {
          #   :username => ENV["WHATCD_USERNAME"],
          #   :password => ENV["WHATCD_PASSWORD"]
          # }


          # c.plugins.plugins << Cinch::Plugins::IMDb
          # c.plugins.options[Cinch::Plugins::IMDb] = {
          #   :standard => lambda do |movie|
          #     msg  = movie.title.dup
          #     msg << " (#{movie.release_date.year})" unless movie.release_date.nil?
          #     msg << " - #{Integer(movie.runtime) / 60} min" unless movie.runtime.nil?
          #     msg << " - #{('★' * movie.rating + '☆' * 10)[0..9]}" unless movie.rating.nil?
          #     msg << " - #{movie.plot}" unless movie.plot.nil?
              
          #     unless movie.genres.nil?
          #       msg << " http://www.imdb.com/title/#{movie.imdb_id}/"
          #     end

          #     return msg
          #   end,
          #   :fact => lambda do |movie, fact, result|
          #     result = "#{Integer(movie.runtime) / 60} min" if fact == 'runtime'
          #     "#{movie.title.capitalize} #{fact}: #{result}"
          #   end
          # }
        end

        on :message, "!help" do |m|
          m.reply "See http://goo.gl/ZFy1V."
        end

        on :message, /^!(\S+)ing/i do |m, char|
          m.reply "#{char}ong"
        end
      end
    end

    def start
      Signal.trap "TERM", &method(:stop)
      Signal.trap "INT", &method(:stop)

      @bot.start
    end

    def stop(signal)
      Thread.new { @bot.quit "Bye" }.join
    end
  end
end