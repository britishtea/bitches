require "cinch/extensions/authentication"

module Bitches
  module Plugins
    class BigBrother
      include Cinch::Plugin
      include Cinch::Extensions::Authentication

      set :plugin_name, "badword"
      set :help, "Usage: !badword (add|delete|list) <badword>."

      match /badword add (.+)/i,     :group => :a, :method => :add_bad_word
      match /badword delete (.+)/i,  :group => :a, :method => :delete_bad_word
      match /badword list/i,         :group => :a, :method => :list_bad_words
      
      listen_to :message,            :group => :a, :method => :listen

      attr_reader :bad_words

      def initialize(*args)
        super

        update_list!
      end

      def add_bad_word(m, bad_word)
        return unless authenticated? m

        Models::Badword.create(:word => bad_word).save
        m.reply "Added \"#{bad_word}\" to the list."

        update_list!
      rescue => e
        handle_exceptions m, e
      end

      def delete_bad_word(m, bad_word)
        return unless authenticated? m

        Models::Badword.first(:word => bad_word).destroy
        m.reply "Removed \"#{bad_word}\" from the list."

        update_list!
      rescue => e
        handle_exceptions m, e
      end

      def list_bad_words(m)
        return unless authenticated? m

        m.reply bad_words.size > 1 ? bad_words.join(", ") : "None."
      rescue => e
        handle_exceptions(m, e)
      end

      def listen(m)
        return unless m.channel?

        user_modes = m.channel.users[m.user]
        
        if ["q", "a", "o", "h"].any? { |mode| user_modes.include?(mode) }
          return
        end

        match = bad_words.find { |word| m.message.include? word }

        unless match.nil?
          if m.action?
            message = "#{m.user} #{m.message.sub("ACTION ", "")}"
          else
            message = "<#{m.user}> #{m.message}"
          end

          Channel(config[:channel]).send "Achtung!! " \
            "#{message.gsub match, Format(:bold, match)}"
        end
      end

    private

      def handle_exceptions(m, e)
        m.reply "Something went wrong."
        bot.loggers.exception e
      end

      def update_list!
        @bad_words = Models::Badword.select(:word).all.map(&:word)
      end
    end
  end
end
