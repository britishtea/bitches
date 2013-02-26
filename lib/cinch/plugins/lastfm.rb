require 'lastfm'

module Cinch
  module Plugins
    class LastFM
      include Cinch::Plugin
      
      set :plugin_name, 'last'
      set :help, 'Usage: !np [<username>], !compare <one> [<two>], ' +
        '!setusername <username>.'
      
      match /np(?: (\S+))?/i,                 :method => :now_playing
      match /co(?:mpare)? (\S+)(?: (\S+))?/i, :method => :compare
      match /setusername (\S+)/i,             :method => :set_username

      match /user(?: (\S+))?/i,               :method => :user
      match /similar(?: (.+))?/i,             :method => :similar

      match /artist(?: (\S+))?/i,             :method => :artist
      match /tag(?: (\S+))?/i,                :method => :tag

      def initialize(*args)
        super

        @client = Lastfm.new config[:api_key], config[:api_secret]
      end

      def now_playing(m, username = nil)
        user = Models::User.first :nickname => username || current_user(m)

        if user.nil? || user.lastfm_name.nil?
          if username.nil?
            m.user.notice "You haven't registered yet, #{m.user.nick} is " +
              "assumed as your last.fm username. You can register with " +
              "!setusername <last.fm username>."
          elsif User(username).channels.one? { |c| c == m.channel }
            m.user.notice "#{username} hasn't registered yet, #{username} is " +
              "assumed as his/her last.fm username."
          end
        end

        track = @client.user.get_recent_tracks(
          :user => user.nil? ? (username || current_user(m)) : user.lastfm_name,
          :limit => 1
        )

        # Some weirdness in the lastfm library. It returns an Array when a track
        # is nowplaying, otherwise it returns a track Hash.
        track = track.first if track.is_a? Array

        if track.nil? || !track.has_key?('nowplaying')
          m.reply "#{username || m.user.nick} isn't playing anything right now."
          return
        end

        artist    = track['artist']['content']
        trackname = track['name']

        m.reply "#{username || m.user.nick} is now playing #{artist} - " +
          "#{track['name']}."
      rescue Lastfm::ApiError => e
        m.reply "Something went wrong (#{e.message.gsub(/\s+/, ' ').strip})."
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong."
      end

      def compare(m, one, two = nil)
        user_one = Models::User.first :nickname => one
        user_two = Models::User.first :nickname => two || current_user(m)

        tasteometer = @client.tasteometer.compare(
          :type1 => 'user', 
          :type2 => 'user',
          :value1 => user_one.nil? ? one : user_one.lastfm_name,
          :value2 => user_two.nil? ? (two || current_user(m)) : user_two.lastfm_name,
          :limit => 5
        )

        score   = Float(tasteometer['score']) * 100
        matches = Integer(tasteometer['artists']['matches'])
        msg     = "#{one} and #{two || m.user.nick} are #{score.round 2}% " +
          "alike."

        if matches > 1
          artists = tasteometer['artists']['artist'].map { |a| a['name'] }

          msg << "They have both listened to #{artists[0..-2].join ', '} " +
            "and #{artists.last}."
        elsif matches == 1
          msg << "They have both listened to #{artists.first}."
        end

        m.reply msg
      rescue Lastfm::ApiError => e
        m.reply "Something went wrong (#{e.message.gsub(/\s+/, ' ').strip})."
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong."
      end

      def set_username(m, username)
        user = Models::User.first_or_create :nickname => current_user(m)
        user.update :lastfm_name => username

        m.reply "You have been registered as #{username}."
      rescue => e
        bot.loggers.error e.message
        m.user.notice "Something went wrong."
      end

      def user(m, user = nil)
      end

      def similar(m, artist = nil)
      end

      def artist(m, artist = nil)
      end

      def tag(m, tag = nil)
      end

    private

      def current_user(m)
        m.user.authname || m.user.nick
      end
    end
  end
end
