# encoding: utf-8

require 'uri'

require 'cinch/helpers/admin'

require 'models/user'
require 'models/choon'
require 'models/tag'

module Cinch
  module Plugins
    class Choons
      include Cinch::Plugin
      include Helpers::Admin
      
      # Internal: An Array of genre Strings that suck.
      SUCK = ['dubstep', 'easy.listening', 'classic.rock']
      
      set :plugin_name, 'choons'
      set :help, 'Usage: !choon [delete] [url] [tag[, tag, ...]].'
      
      match /choon -{0,2}delete (.+)/i, :group => :choon, :method => :delete_choon
      match /choon (http\S*)(.+)?/i, :group => :choon, :method => :add_choon
      match /choon$/i,               :group => :choon, :method => :random
      match /choon (\S+)/i,          :group => :choon, :method => :random
      
      # Initializes the plugin.
      def initialize(*args)
        super
        
        @channel = self.config[:channel]
      end
      
      # Public: Sends back a random choon.
      #
      # m   - The Cinch::Message.
      # tag - The tag(s) String that the Choons will be filtered on 
      #       (default: nil).
      #
      # Returns nothing.
      def random(m, tag = nil)
        if tag.nil? || tag.empty?
          choons = Models::Choon.all
        else
          choons = Models::Tag.first(:name => tag.chomp).choons
        end
        
        choon = choons.shuffle.first
        
        if !tag.nil? && SUCK.include?(tag.downcase)
          m.channel.action "thinks #{tag.downcase} sucks"
          sleep rand 2..8
          m.reply "Ok then #{m.user.nick}, here you go: #{choon.url}."
        else
          m.reply "Here's one: #{choon.url}"
        end
      rescue => e
        m.reply "Nobody likes #{tag}. Nobody likes you. Please. Just. Leave."
        bot.loggers.error e.message
      end
      
      # Adds a choon to the database or updates its tags.
      #
      # m    - The Cinch::Message.
      # url  - The URL String.
      # tags - The tags as a String, separated by spaces.
      #
      # Returns nothing.
      def add_choon(m, url, tags)
        choon = Models::Choon.first_or_create :url => URI::parse(url)
        
        if choon.user.nil?
          choon.user = Models::User.first_or_create(:nickname => m.user.nick)
        end
        
        unless tags.nil?
          tags.split(' ').map do |t| 
            choon.tags << Models::Tag.first_or_create(:name => t)
          end
        end
        
        choon.save!
        bot.loggers.info "New choon (#{choon.id}) added to database by #{m.user.nick}"
        
        m.reply "This choon has been george choonied, sir."
      rescue => e
        m.reply "A wild error appeared. You're out of pokéballs."
        bot.loggers.error e.message
      end
      
      # Public: Deletes a choon from the database.
      #
      # m   - The Cinch::Message
      # url - The URL String of the Choon that should be deleted.
      #
      # Returns nothing.
      def delete_choon(m, url)
        choon = Models::Choon.first :url => url
        
        if authorized? Channel(@channel), m.user
          choon.destroy!
          m.reply "Done, Mrs Robinson. Jesus loves you more than you will know."
        else
          bot.loggers.info "#{m.user.nick} tried to delete a choon. LOL!"
          m.reply "I just don't know what to do with myself"
        end
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong, choon probably didn't exist"
      end
    end
  end
end