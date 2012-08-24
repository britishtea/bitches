require 'net/http'

require 'models/user'
require 'models/picture'

module Cinch
  module Plugins
    class Pictures
      include Cinch::Plugin
  
      set :plugin_name, 'pictures'
      set :help, "Usage: !del[ete] url."
      
      match /del(?:ete)? (.+)/i, :group => :uris, :method => :delete
      match /(.*http.*)/,        :group => :uris, :method => :add_picture, 
                                 :use_prefix => false
  
      # Internal: Initializes the plugin and opens a SQLite database connection.
      def initialize(*args)
        super

        @url     = self.config[:url]
        @channel = self.config[:channel]
      end
  
      # Public: Saves image URLs to an SQLite database.
      def add_picture(m, message)
        return if message =~ /(nsfl|nsfw)/i
        
        URI.extract(message, ["http", "https"]) do |uri|
          # Only allow images
          res = Net::HTTP.get_response URI(uri)
          next unless res['content-type'] =~ /^image\//i
          
          # 4chan images are short-lived
          next if URI(uri).host == "images.4chan.org" 
          
          user = Models::User.first_or_create :nickname => m.user.nick
          user.save!
          
          picture      = Models::Picture.create :url => uri
          picture.user = user
          picture.save!
          
          bot.loggers.debug "Successfully added a picture (#{picture.url})."
        end
      rescue => e
        bot.loggers.error e.message
      end
      
      # Public: Removes an offensive link from the gallery.
      def delete(m, uri)
        picture = Models::Picture.first :url => uri
        
        if authorized? Channel(@channel), m.user
          picture.destroy!
          m.user.notice 'Aye!'
        else
          m.reply 'Lol, sorry brochachi.'
        end
      rescue => e
        m.user.notice "I'm sorry, that didn't work."
        bot.loggers.error e.message
      end
  
    private
    
      # Internal: Checks wether the user is an admin or not
      #
      # channel - The Cinch::Channel.
      # user    - The Cinch::User that needs to be authorized.
      #
      # Returns a Boolean.
      def authorized?(channel, user)
        ['q', 'a', 'o', 'h'].each do |mode|
          return true if channel.users[user].include? mode
        end
        
        false
      end
    end 
  end
end