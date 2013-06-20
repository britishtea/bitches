require 'httparty'

require 'cinch/extensions/authentication'

module Cinch
  module Plugins
    class Media
      include Cinch::Plugin
      include Cinch::Extensions::Authentication
  
      set :plugin_name, 'media'
      set :help, "Usage: !delete <url>."
      
      match /del(?:ete)? (.+)/i, :group => :uris, :method => :delete
      match /(.*http.*)/i,       :group => :uris, :method => :add_media, 
                                 :use_prefix => false
  
      # Internal: Initializes the plugin and opens a SQLite database connection.
      def initialize(*args)
        super

        @url           = config[:url]
        @secret        = config[:secret]
        @channels      = config[:channels] || []
        @ignored_hosts = config[:ignored_hosts] || []
        @ignored_tags  = config[:ignored_tags] || []
      end

      # Public: Adds media to the database
      def add_media(m)
        return if ignore? m.message 
        return unless @channels.include? m.channel

        URI.extract m.message, ['http', 'https'] do |uri|
          begin
            parsed_uri = URI(uri)
            host       = parsed_uri.host

            next if @ignored_hosts.include? host

            type     = HTTParty.get(uri).headers['content-type']
            yt_uris  = %w(youtube.com youtu.be)

            next unless host.end_with?(*yt_uris) || type.start_with?('image/')

            response = HTTParty.post "#{@url}/media", query: {
              user: (m.user.authname || m.user.nick), url: uri, message: m.to_s, 
              secret: @secret
            }
          rescue => e
            bot.loggers.error e.message
            next
          end
        end
      end

      # Public: Removes an offensive link from the database.
      def delete(m, uri)
        return unless authenticated? m

        response = HTTParty.delete "#{@url}/media", query: {
          url: uri, secret: @secret
        }

        case response.code
          when "200" then m.reply 'Done'
          when "500" then raise "Destroying #{uri} failed."
          when "401" then raise "The secret is incorrect."
          else bot.loggers.error response.inspect
        end
      rescue => e
        bot.loggers.error e.message
        m.user.notice 'Something went wrong.'
      end

    private

      # Public: Checks if the message should be ignored.
      #
      # message - A Cinch::Message
      #
      # Returns a Boolean.
      def ignore?(message)
        ignore = false

        @ignored_tags.each do |tag|
          if tag.is_a? Regexp
            ignore = true if message =~ tag
          else
            ignore = true if message.downcase.include? tag.downcase
          end
        end

        ignore
      end
    end 
  end
end
