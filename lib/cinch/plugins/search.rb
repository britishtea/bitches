# encoding: utf-8
require "bitches/helpers"
require "cgi"
require "net/http"
require "uri"
require "google-search"
require "youtube_it"

module Cinch
  module Plugins
    class Search
      include Cinch::Plugin

      set :plugin_name => "search",
          :help        => "Usage: !<g|google|yt|youtube> <search term>"

      match /google (.+)/s,  :method => :google
      match /g (.+)/s,       :method => :g
      match /youtube (.+)/s, :method => :youtube
      match /yt (.+)/s,      :method => :yt 

      def initialize(*args)
        super

        @youtube = YouTubeIt::Client.new
      end

      def g(m, query)
        m.reply search_google(query, 1)
      end

      def google(m, query)
        m.reply search_google(query, 3)
      end

      def yt(m, query)
        m.reply search_youtube(query, 1)
      end

      def youtube(m, query)
        m.reply search_youtube(query, 3)
      end

    private

      def search_google(query, n)
        results = Google::Search::Web.new(:query => query).first(n)

        if results.empty?
          "No result#{"s" if n > 1} for \"#{query}\"."
        else
          results.map { |item| create_google_preview item }.join " | "
        end
      rescue => e
        bot.loggers.exception e
        "Something went wrong while searching Google."
      end

      def create_google_preview(item)
        "#{CGI.unescape_html item.title} - #{shorten_uri item.uri}"
      end

      def search_youtube(query, n)
        results = @youtube.videos_by(:query => query, :per_page => n).videos

        if results.empty?
          "No result#{"s" if n > 1} for \"#{query}\"."
        else
          results.map { |video| create_youtube_preview video }.join " | "
        end
      rescue => e
        bot.loggers.exception e
        "Something went wrong while searching YouTube."
      end

      def create_youtube_preview(video)
        preview   = Bitches::Helpers.youtube_preview video
        short_url = shorten_uri video.player_url

        "#{preview} - #{short_url}"
      end

      ISGD_URI = URI "http://is.gd/create.php"

      def shorten_uri(uri)
        res = Net::HTTP.post_form ISGD_URI, :format => "simple", :url => uri

        res.code == "200" ? res.body : uri
      rescue => e
        bot.loggers.exception e
        uri
      end
    end
  end
end
