require "clap"
require "shellwords"
require "whatcd"

module Bitches
  module Plugins
    class WhatCD
      include Cinch::Plugin

      set :plugin_name => "what",
          :help        => "Usage: !what <searchterm> [options]"

      match /what (.+)/i,   :method => :torrent
      match /whois (\S+)/i, :method => :whoisititsgrandpubahoney

      # Initializes the plugin.
      def initialize(*args)
        super

        @client = ::WhatCD::Client.new

        if config.key?(:cookie)
          @client.set_cookie config[:cookie]
        elsif config.key?(:username) && config.key?(:password)
          @client.authenticate config[:username], config[:password]
        else
          warn "Please configure a cookie or username/password."
        end
      rescue ::WhatCD::AuthError => e
        warn "Authenticating with What.CD failed."
        require "pry" and binding.pry
      end

      SEARCH_OPTIONS = {  
        "--tag"  => proc { |tag|  options[:taglist] << tag  },
        "--year" => proc { |year| options[:year]     = year }
      }

      def torrent(m, arguments)
        options = { :taglist => [] }
        query   = Clap.run Shellwords.split(arguments),
          "--tag"  => proc { |tag|  options[:taglist] << tag  },
          "--year" => proc { |year| options[:year]     = year }

        torrent = find_torrent query.join(" "), options

        if torrent.nil?
          m.reply "No results for \"#{options[:searchstr]}\""
        else
          m.reply format_torrent(torrent)
        end
      rescue Errno::ETIMEDOUT
        m.reply "Timed out while searching \"#{query.join " "}\" on What.CD."
      rescue => e
        handle_exeptions m, e
      end

      def whoisititsgrandpubahoney(m, nickname)
        user = User(nickname)

        if user.unknown?
          m.reply "There is no user with nickname \"#{nickname}\"."
        elsif user.host.end_with? ".what.cd"
          m.reply format_user(user)
        else
          m.reply "#{nickname} did not speak with Drone yet."
        end
      rescue => e
        m.reply "Something went wrong. Does \"#{nickname}\" exist?"
        bot.loggers.error 
      end

    private

      def find_torrent(query, options)
        parameters = options.merge :searchstr => query
        @client.fetch(:browse, parameters)["results"].first
      end

      BASE_URI = URI.parse "https://what.cd/"

      def format_torrent(torrent)
        require "pry" and binding.pry

        url       = BASE_URI + "torrents.php"
        url.query = URI.encode_www_form :id => torrent["groupId"]

        if torrent.key? "category"
          preview = torrent["groupName"]
        else
          preview = "#{torrent["artist"]} - #{torrent["groupName"]} " \
            "(#{torrent["groupYear"]})"
        end

        "#{CGI.unescapeHTML preview} => #{url}"
      end

      def format_user(user)
        what_name    = user.host.split(".").first
        what_profile = BASE_URI + "user.php?id=#{user.user}"

        "#{user.nick} is #{what_name} on what.cd => #{what_profile}."
      end

      def handle_exeptions(m, e)
        m.reply "Something went wrong."
        bot.loggers.exception e
      end 
    end
  end
end
