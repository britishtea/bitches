require 'cgi'
require 'google-search'
require 'shortly'
require 'youtube_it'

module Cinch
  module Plugins
    class Google
      include Cinch::Plugin

      set :plugin_name, 'google'
      set :help, 'Usage: !google <search term>'

      match /google more/s,  :method => :more,    :group => :google
      match /google (.+)/s,  :method => :google,  :group => :google
      match /g more/s,       :method => :more,    :group => :g
      match /g (.+)/s,       :method => :g,       :group => :g
      match /youtube more/s, :method => :more,    :group => :youtube
      match /youtube (.+)/s, :method => :youtube, :group => :youtube
      match /yt more/s,      :method => :more,    :group => :yt
      match /yt (.+)/s,      :method => :yt,      :group => :yt

      NoResults = Class.new StandardError

      def initialize(*args)
        super

        @isgd    = Shortly::Clients::Isgd
        @more    = {}
        @youtube = YouTubeIt::Client.new
      end

      def more(m)
        return unless @more.has_key? m.user

        url = "https://google.com/search?q=#{CGI.escape @more[m.user]}"
        m.reply "More results on #{@isgd.shorten(url).shorturl}"
      end

      def google(m, query)
        results = google_search(m, query).first 3
        size    = results.size
        msg     = results.inject("Top #{size > 3 ? 3 : size}:") do |obj, item|
          title = CGI.unescape_html item.title
          obj << " #{title} - #{@isgd.shorten(item.uri).shorturl} |"
        end

        m.reply msg[0..-3]
      rescue NoResults => e
        m.reply e.message
      end

      def g(m, query)
        result = google_search(m, query).first
        title  = CGI.unescape_html result.title
        
        m.reply "#{title} - #{@isgd.shorten(result.uri).shorturl}"
      rescue NoResults => e
        m.reply e.message
      end

      def youtube(m, query)
        results = youtube_search(m, query).first 3
        size    = results.size
        msg     = results.inject("Top #{size > 3 ? 3 : size}:") do |obj, item|
          title    = CGI.unescape_html item.title
          duration = Time.at(item.duration).gmtime.strftime '%R:%S'
          duration = duration[3..-1] if duration.start_with? '00'
          url      = @isgd.shorten(item.player_url).shorturl

          obj << " #{title} [#{duration}] - #{url} |"
        end

        m.reply msg[0..-3]
      rescue NoResults => e
        m.reply e.message
      end

      def yt(m, query)
        result = youtube_search(m, query).first

        title    = CGI.unescape_html result.title
        duration = Time.at(result.duration).gmtime.strftime '%R:%S'
        duration = duration[3..-1] if duration.start_with? '00'
        url      = @isgd.shorten(result.player_url).shorturl

        m.reply "#{title} [#{duration}] - #{url}"
      rescue NoResults => e
        m.reply e.message
      end

    private

      def google_search(m, query)
        @more[m.user] = query
        results       = ::Google::Search::Web.new :query => query
        raise NoResults, "No results" if results.response.estimated_count == 0

        return results      
      end

      def youtube_search(m, query)
        @more[m.user] = query
        results       = @youtube.videos_by :query => query, :per_page => 3
        raise NoResults, "No results" if results.total_result_count == 0

        return results.videos
      end
    end
  end
end
