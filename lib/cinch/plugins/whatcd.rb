# encoding: utf-8

require 'whatcd'
require 'slop'

module Cinch
  module Plugins
    class What
      include Cinch::Plugin
      
      set :plugin_name, 'what'
      set :help, 'Usage: !what [(request|rippy|torrent|user)] [<searchterm>] ' +
        '[--<parameter> <value> ...].'
      
      match /what -{0,2}requests? (.+)/i, :group => :what, :method => :request
      match /what -{0,2}rippy/i,          :group => :what, :method => :rippy
      match /what -{0,2}torrents? (.+)/i, :group => :what, :method => :torrent
      match /what -{0,2}users? (.+)/i,    :group => :what, :method => :user
      match /what (.+)?/i,                :group => :what, :method => :torrent
      
      # Initializes the plugin.
      def initialize(*args)
        super

        WhatCD::authenticate self.config[:username], self.config[:password]
      end

      def request(m, query)
        a = query.split '--', 2

        params = get_options "--#{a[1]}".strip.split if a.count > 1
        (params ||= {})[:search] = a.first.strip.gsub '-', ''

        results = WhatCD::Requests(params)['results']

        if results.empty?
          m.reply "No results :("
        else
          request = results.first
          urls    = urls "requests.php?action=view&id=#{request['requestId']}"

          m.reply "#{CGI.unescapeHTML request['title']} => #{urls}"
        end
      rescue => e
        error m, e
      end

      def torrent(m, query)
        a = query.split '--', 2

        params = get_options("--#{a[1]}".strip.split) if a.count > 1
        (params ||= {})[:searchstr] = a.first.strip.gsub '-', ''

        results = WhatCD::Browse(params)['results']

        if results.empty?
          m.reply "No results :("
        else
          t    = results.first
          urls = urls "torrents.php?id=#{t['groupId']}"

          if !t.has_key? 'category'
            msg = "#{t['artist']} - #{t['groupName']} (#{t['groupYear']})"
          else
            msg = "#{t['groupName']}"
          end

          m.reply "#{CGI.unescapeHTML msg} => #{urls}"
        end
      rescue => e
        error m, e
      end

      def user(m, username)
        results = WhatCD::Usersearch(:search => username)['results']

        if results.empty?
          m.reply "No results :("
        else
          user = results.first
          msg = "#{CGI.unescapeHTML user['username']}"

          m.reply "#{msg} => #{urls "user.php?id=#{user['userId']}"}"
        end
      rescue => e
        error m, e
      end

    private

      # Internal: Constructs some URLs.
      #
      # resource - The resource string (e.g. user.php?id=3)
      #
      # Returns a String.
      def urls(resource)
        "https://what.cd/#{resource}"
      end

      # Internal: Handles errors.
      #
      # m - The Cinch::Message.
      # e - The Exception.
      def error(m, e)
        bot.loggers.error e.message

        m.reply "Sorry, something went wrong."
      end

      # Internal: Turns an options string into an options Hash
      #
      # options_string - A String of options.
      #
      # Returns a Hash.
      def get_options(options_string)
        opts = Slop.new :autocreate => true
        opts.parse options_string

        opts.to_hash.delete_if { |k,v| v.nil? }
      end
    end
  end
end
