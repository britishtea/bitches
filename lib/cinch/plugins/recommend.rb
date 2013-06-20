module Cinch
  module Plugins
    class Recommend
      include Cinch::Plugin
      
      set :plugin_name, 'rec'
      set :help, 'Usage: !rec (get|clear|<username> <recommendation>).'
      
      match /rec get/i,        :group => :rec, :method => :get
      match /rec clear/i,      :group => :rec, :method => :clear
      match /rec (\S+) (.+)/i, :group => :rec, :method => :add

      def get(m)
        user = Models::User.find_user(m.user.authname || m.user.nick)

        if user.recommendations.empty?
          m.reply "No recommendations."
          return
        end

        message = user.recommendations.inject("") do |msg, rec|
          msg << "#{rec.source.nickname} recommends #{rec.recommendation}. "
        end

        if message.length > (510 - 15 - bot.mask.to_s.length)
          m.user.msg message.rstrip
        else
          m.reply message.rstrip
        end
      end

      def clear(m)
        user = Models::User.find_user(m.user.authname || m.user.nick)

        if user.recommendations.destroy
          m.reply "Your recommendations were deleted."
        else
          m.reply "Something went wrong."
        end
      end

      def add(m, user, recommendation)
        from = Models::User.find_user(m.user.authname || m.user.nick)
        user = Models::User.find_user(User(user).authname || user)

        rec = Models::Recommendation.new(
          :user => user,
          :source => from,
          :recommendation => recommendation
        )

        m.reply rec.save ? "Okay." : "Something went wrong."
      end
    end
  end
end
