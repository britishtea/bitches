require 'net/http'

require 'cinch/helpers/admin'

module Cinch
  module Plugins
    class Pictures
      include Cinch::Plugin
      include Helpers::Admin
  
      set :plugin_name, 'pictures'
      set :help, "Usage: !del[ete] url."
      
      match /picture -{0,2}del(?:ete)? (.+)/i, :group => :uris, :method => :delete
      match /del(?:ete)? (.+)/i,         :group => :uris, :method => :delete
      match /(.*http.*)/,                :group => :uris, :method => :add_picture, 
                                         :use_prefix => false
  
      # Internal: Initializes the plugin and opens a SQLite database connection.
      def initialize(*args)
        super

        @url           = self.config[:url]
        @channel       = self.config[:channel]
        @ignored_hosts = self.config[:ignored_hosts]
        @ignored_tags  = self.config[:ignored_tags]
      end
  
      # Public: Saves image URLs to an SQLite database.
      def add_picture(m, message)
        ignore = false

        @ignored_tags.each do |tag|
          if tag.is_a? Regexp
            ignore = true if message =~ tag
          else
            ignore = true if message.downcase.include? tag.downcase
          end
        end

        return if ignore == true
        
        URI.extract(message, ["http", "https"]) do |uri|
          # Only allow images
          res = Net::HTTP.get_response URI(uri)
          next unless res['content-type'] =~ /^image\//i
          
          # 4chan images are short-lived
          next if @ignored_hosts.include? URI(uri).host
          
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
          m.channel.action 'giggles'
        end
      rescue => e
        bot.loggers.error e.message
        m.user.notice "I'm sorry, that didn't work."
      end
    end 
  end
end
