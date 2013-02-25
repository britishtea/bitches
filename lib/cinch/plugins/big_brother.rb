require 'cinch/extensions/authentication'

module Cinch
  module Plugins
    class BigBrother
      include Cinch::Plugin
      include Cinch::Extensions::Authentication

      set :plugin_name, 'badword'
      set :help, 'Usage: !badword (add|delete|list) <badword>.'

      match /badword add (.+)/i,     :group => :a, :method => :add_bad_word
      match /badword delete (.+)/i,  :group => :a, :method => :remove_bad_word
      match /badword list/i,         :group => :a, :method => :list_bad_words
      
      listen_to :message,            :group => :a, :method => :listen

      def initialize(*args)
        super

        @bad_words = get_bad_words
        @channel   = self.config[:channel]
      end

      def add_bad_word(m, bad_word)
        return unless authenticated? m

        word = Models::Badword.create :word => bad_word
        word.save

        m.user.notice 'Aye!'
        bot.loggers.info "Added a new bad word: #{bad_word}"

        @bad_words = get_bad_words
      rescue => e
        bot.loggers.error "Something went wrong: #{e.message}"
        m.user.notice "Soz :( Didn't work"
      end

      def remove_bad_word(m, bad_word)
        return unless authenticated? m

        word = Models::Badword.first :word => bad_word
        word.destroy!

        m.user.notice 'Aye!'
        bot.loggers.info "Removed a bad word: #{bad_word}"

        @bad_words = get_bad_words
      rescue => e
        bot.loggers.error "Something went wrong: #{e.message}"
        m.user.notice "Soz :( Didn't work"
      end

      def list_bad_words(m)
        if @bad_words.size > 1
          m.user.notice "#{@bad_words[0..-2].join(', ')} and #{@bad_words.last}"
        else
          m.user.notice @bad_words.first || 'none'
        end
      end

      def listen(m)
        return unless m.channel?
        return if m.message.start_with?('!badword')

        [:q, :a, :o, :h].each do |mode|
          return if m.channel.users[m.user].include? mode.to_s
        end

        msg = m.message

        @bad_words.each do |bad_word|
          if msg.downcase.include? bad_word
            msg.gsub! bad_word, Format(:bold, bad_word)
            
            if m.action?
              msg.gsub! 'ACTION ', ''
              Channel(@channel).send "Achtung!! #{m.user.nick} #{msg}"
            else
              Channel(@channel).send "Achtung!! <#{m.user.nick}> #{msg}"
            end

            return
          end
        end
      end

    private

      def get_bad_words
        Models::Badword.all(:id.gt => 0).map &:word
      end
    end
  end
end
