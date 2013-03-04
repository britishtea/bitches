# encoding: utf-8
require 'httparty'
require 'nokogiri'
require 'cgi'

module Cinch
  module Plugins
    class Title
      include Cinch::Plugin
      include HTTParty
      
      match /.*http.*/, :use_prefix => false, :method => :handle_url, :group => :url
      match /www\..*/,  :use_prefix => false, :method => :handle_url, :group => :url

      class << self
        attr_reader :cookies, :default_handler, :handlers
        
        def cookie(host, cookiestring)
          (@cookies ||= {})[host] = cookiestring
        end

        def handler(host, &handler)
          (@handlers ||= {})[host] = handler
        end

        def default(&handler)
          @default_handler = handler
        end
      end

      def initialize(*args)
        super

        @cookies  = self.class.cookies || {}
        @handlers = self.class.handlers || {}
        @default  = self.class.default_handler || Proc.new do |m, uri, cookies|
          options          = { :follow_redirects => true }
          options[:header] = { 'Cookie' => cookies } unless cookies.nil?
          res              = HTTParty.get uri.to_s, options

          if res.code == 200 && res.headers['content-type'] =~ /text\/html/s
            title = Nokogiri::HTML(res.body).at_xpath('//title').text
            
            unless title.nil?
              title.gsub(/\s+/, ' ').strip!
              m.reply "Title: #{CGI.unescape_html(title).strip}"
            end
          end
        end
      end
      
      def handle_url(m)
        msg = m.message.gsub ' www.', 'http://www.'

        URI.extract msg, ["http", "https"] do |uri|
          begin
            next if ignore uri

            uri     = URI uri
            host    = uri.host.split('.')[-2..-1].join '.' # Allows subdomains
            handler = @handlers[host] || @default

            unless handler.call m, uri, @cookies[uri.host]
              @default.call m, uri, @cookies[uri.host]
            end
          rescue => e
            bot.loggers.error e.message
            bot.loggers.error e.backtrace
            next
          end
        end
      end

    private
      
      def ignore(uri)
        ignore = ["jpg$", "JPG$", "jpeg$", "gif$", "png$", "bmp$", "pdf$",
          "jpe$"]
        ignore.concat(config["ignore"]) if config.key? "ignore"
        
        ignore.each { |re| return true if uri =~ /#{re}/ }
        
        false
      end
    end

    require 'youtube_it'

    Title.handler('youtube.com') do |m, uri, cookies|
      begin
        client = YouTubeIt::Client.new

        video    = client.video_by uri.to_s
        rating   = video.rating.average.ceil.times.inject('') { |x| x << '★' } +
          '☆☆☆☆☆'
        duration = Time.at(video.duration).gmtime.strftime '%R:%S'

        m.reply "#{video.title} [#{duration}] - #{rating[0..4]}"

        next true
      rescue => e
        next false
      end
    end

    require 'filmbuff'

    Title.handler('imdb.com') do |m, uri, cookies|
      begin
        uri.path.match /^\/title\/(tt\d{7})\/$/ do |matchdata|
          imdb  = FilmBuff::IMDb.new
          movie = imdb.find_by_id matchdata.captures.first

          msg  = movie.title
          msg << " (#{movie.release_date.year})" unless movie.release_date.nil?
          msg << " - #{movie.plot}" unless movie.plot.nil?
          msg << " [#{movie.genres.join ', '}]" unless movie.genres.nil?
          
          m.reply msg
        end

        next !! uri.path.match(/^\/title\/(tt\d{7})\/$/)
      rescue => e
        puts e.message, e.backtrace
        next false
      end
    end
  end
end
