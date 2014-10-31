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


          if ENV.key? "MONITOR_CHANNEL"
            require "bitches/plugins/big_brother"

            c.plugins.plugins << Bitches::Plugins::BigBrother
            c.plugins.options[Bitches::Plugins::BigBrother] = {
              :channel => ENV["MONITOR_CHANNEL"]
            }
          end


          if ENV.key? "NICKSERV_PASSWORD"
            require "cinch/plugins/identify"

            c.plugins.plugins << Cinch::Plugins::Identify
            c.plugins.options[Cinch::Plugins::Identify] = {
              :password => ENV["NICKSERV_PASSWORD"],
              :type     => :nickserv
            }
          end

          if ENV.key?("LASTFM_KEY") && ENV.key?("LASTFM_SECRET")
            require "bitches/plugins/lastfm"

            c.plugins.plugins << Bitches::Plugins::LastFM
            c.plugins.options[Bitches::Plugins::LastFM] = {
              :api_key    => ENV["LASTFM_KEY"],
              :api_secret => ENV["LASTFM_SECRET"]
            }
          end


          require "bitches/plugins/links"

          c.plugins.plugins << Bitches::Plugins::Links


          if ENV.key?("MEDIA_URL") && ENV.key?("MEDIA_SECRET")
            require "bitches/plugins/media"

            c.plugins.plugins << Bitches::Plugins::Media
            c.plugins.options[Bitches::Plugins::Media] = {
              :url           => ENV["MEDIA_URL"],
              :secret        => ENV["MEDIA_SECRET"],
              :channels      => ENV["CHANNELS"].split(","),
              :ignored_hosts => ["https://fbcdn-sphotos-c-a.akamaihd.net/"],
              :ignored_tags  => ["nsfw", "nsfl", "ignore"]
            }
          end


          require "cinch/plugins/preview"
          require "cinch/plugins/preview/imdb"
          require "cinch/plugins/preview/title"
          require "cinch/plugins/preview/youtube"

          c.plugins.plugins << Cinch::Plugins::Preview


          require "cinch/plugins/search"

          c.plugins.plugins << Cinch::Plugins::Search


          # require "cinch/plugins/slang"

          # c.plugins.plugins << Cinch::Plugins::Slang


          require "bitches/plugins/weather"

          c.plugins.plugins << Bitches::Plugins::Weather


          if ENV.key?("WHATCD_COOKIE")
            require "cinch/plugins/preview/whatcd"
            require "bitches/plugins/whatcd"

            c.plugins.plugins << Bitches::Plugins::WhatCD
            c.plugins.options[Bitches::Plugins::WhatCD] = {
              :cookie => ENV["WHATCD_COOKIE"]
            }
          end


          require "cinch/plugins/imdb"

          c.plugins.plugins << Cinch::Plugins::IMDb
        end

        on :message, "!help" do |m|
          m.reply "See http://goo.gl/ZFy1V."
        end

        on :message, /^!(\S+)ing$/i do |m, char|
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
