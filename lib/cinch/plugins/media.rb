require 'net/http'

require 'cinch/extensions/authentication'

module Cinch
  module Plugins
    class Media
      include Cinch::Plugin
      include Cinch::Extensions::Authentication
  
      set :plugin_name, 'media'
      set :help, "Usage: !media delete <url>."
      
      match /(?:media )?del(?:ete)? (.+)/i, :group => :uris, :method => :delete
      match /(.*http.*)/i,                :group => :uris, :method => :add_media, 
                                          :use_prefix => false
  
      # Internal: Initializes the plugin and opens a SQLite database connection.
      def initialize(*args)
        super

        @url           = self.config[:url]
        @channel       = self.config[:channel]
        @ignored_hosts = self.config[:ignored_hosts]
        @ignored_tags  = self.config[:ignored_tags]
      end

      # Public: Adds media to the database
      def add_media(m)
        return if ignore?(m.message)
        #return unless @channels.include?(m.channel)

        URI.extract m.message, ['http', 'https'] do |uri|
          next if @ignored_hosts.include? URI(uri).host

          user = Models::User.first_or_create :nickname => m.user.nick

          if URI(uri).host =~ /youtu(\.be.*|be\.\S{1,4}.*)/i
            add_video uri, user
          elsif Net::HTTP.get_response(URI(uri))['content-type'] =~ /^image\//i
            add_picture uri, user
          end
        end
      end

      # Public: Removes an offensive link from the database.
      def delete(m, uri)
        return unless authenticated? m
        opts  = { :url => uri }
        media = Models::Video.first(opts) || Models::Picture.first(opts)
        media.destroy!
        
        m.user.notice 'Aye!'
      rescue => e
        bot.loggers.error e.message
        m.user.notice "I'm sorry, that didn't work."
      end

    private

      # Public: Saves image URLs to a database.
      #
      # uri  - A uri String.
      # user - A Models::User.
      def add_picture(uri, user)
        picture      = Models::Picture.create :url => uri
        picture.user = user
        picture.save!
        
        bot.loggers.info "Successfully added a picture (#{picture.url})."
      rescue => e
        bot.loggers.error e.message
      end

      # Public: Saves video URLs to a database.
      #
      # uri  - A uri String.
      # user - A Models::User.
      def add_video(uri, user) 
        video      = Models::Video.create :url => uri
        video.user = user
        video.save!

        bot.loggers.info "Successfully added a video (#{video.url})."
      rescue => e
        bot.loggers.error e.message
      end

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
