require 'httparty'
require 'nokogiri'
require 'cgi'

module Cinch
  module Plugins
    class Title
      include Cinch::Plugin
      include HTTParty
      
      match /.*http.*/, :use_prefix => false, :method => :handle_url
      match /www\..*/,  :use_prefix => false, :method => :handle_url

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
              m.reply "Title: #{CGI.unescape_html title}"
            end
          end
        end
      end
      
      def handle_url(m)
        msg = m.message.gsub 'www.', 'http://www.'

        URI.extract msg, ["http", "https"] do |uri|
          begin
            next if ignore uri

            uri     = URI uri
            handler = @handlers[uri.host] || @default

            handler.call m, uri, @cookies[uri.host]
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
  end
end
