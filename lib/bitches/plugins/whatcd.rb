require "bitches/helpers"
require "clap"
require "date"
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

        if config.key? :channels
          @latest = DateTime.now
          
          timer = Timer(600, &method(:announcements))
          timer.start
        else
          warn "Announcements are disabled because no channels were configured."
        end

        if config.key?(:cookie)
          @client.set_cookie config[:cookie]
        elsif config.key?(:username) && config.key?(:password)
          @client.authenticate config[:username], config[:password]
        else
          warn "Please configure a cookie or username/password."
        end
      rescue ::WhatCD::AuthError => e
        warn "Authenticating with What.CD failed."
      end

      def announcements
        news = @client.fetch(:announcements)

        announcements = news["announcements"]
        announcements.sort_by! { |a| DateTime.parse a["newsTime"] }

        blog_posts = news["blogPosts"]
        blog_posts.sort_by { |p| DateTime.parse p["blogTime"] }

        newest = announcements[-1]

        if DateTime.parse(newest["newsTime"]) > @latest
          @latest = DateTime.now

          config[:channels].each do |channel|
            Channel(channel).send format_announcement(newest)
          end
        end

        newest = blog_posts[-1]

        if DateTime.parse(newest["blogTime"]) > @latest
          @latest = DateTime.now

          config[:channels].each do |channel|
            Channel(channel).send format_blog_post(newest)
          end
        end
      rescue => e
        bot.loggers.exception e
      end

      def torrent(m, arguments)
        options = { :taglist => [] }
        query   = Clap.run Shellwords.split(arguments),
          "--tag"  => proc { |tag|  options[:taglist] << tag  },
          "--year" => proc { |year| options[:year]     = year }
        query   = query.join " "

        torrent = find_torrent query, options

        if torrent.nil?
          m.reply "No results for \"#{query}\""
        else
          m.reply format_torrent(torrent)
        end
      rescue Errno::ETIMEDOUT
        m.reply "Timed out while searching \"#{query}\" on What.CD."
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
        torrent   = @client.fetch :torrentgroup, :id => torrent["groupId"]
        url       = BASE_URI + "torrents.php"
        url.query = URI.encode_www_form :id => torrent["groupId"]

        "#{Bitches::Helpers.whatcd_torrentgroup_preview torrent} => #{url}"
      end

      def format_user(user)
        url  = BASE_URI + "user.php?id=#{user.user}"
        user = @client.fetch :user, :id => user.user

        "#{Bitches::Helpers.whatcd_user_preview user} => #{url}"
      end

      def format_announcement(announcement)
        title = announcement["title"]
        url   = BASE_URI + "index.php#news#{announcement["newsId"]}"

        "[New Announcement] #{title} => #{url}"
      end

      def format_blog_post(blog_post)
        title = blog_post["title"]
        id    = blog_post["threadId"]
        url   = BASE_URI + "forums.php?action=viewthread&threadid=#{id}"

        "[New blog post] #{title} => #{url}"
      end

      def handle_exeptions(m, e)
        m.reply "Something went wrong."
        bot.loggers.exception e
      end 
    end
  end
end
