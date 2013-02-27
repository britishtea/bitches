require 'lastfm'

module Cinch
  module Plugins
    class LastFM
      include Cinch::Plugin
      
      set :plugin_name, 'last'
      set :help, 'Usage: see http://goo.gl/ZFy1V.'
      
      match /np(?: (\S+))?/i,                   :method => :now_playing
      match /co(?:mpare)? (\S+)(?: (\S+))?/i,   :method => :compare
      match /setusername (\S+)/i,               :method => :set_username
      match /(?:getusername|user)(?: (\S+))?/i, :method => :get_username
      match /similar(?: (.+))?/i,               :method => :similar
      match /artist(?: (.+))?/i,                :method => :artist

      def initialize(*args)
        super

        @client = Lastfm.new config[:api_key], config[:api_secret]
      end

      def now_playing(m, username = nil)
        track = @client.user.get_recent_tracks(
          :user => find_lastfm_username(m, username),
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
        m.reply e.message.gsub(/\s+/, ' ').strip
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong."
      end

      def compare(m, one, two = nil)
        user     = Models::User.first :nickname => one
        username = user.nil? || user.lastfm_name.nil? ? one : user.lastfm_name

        tasteometer = @client.tasteometer.compare(
          :type1 => 'user', 
          :type2 => 'user',
          :value1 => username,
          :value2 => find_lastfm_username(m, two), 
          :limit => 5
        )

        score   = Float(tasteometer['score']) * 100
        matches = Integer(tasteometer['artists']['matches'])
        msg     = "#{one} and #{two || m.user.nick} are #{score.round 2}% " +
          "alike."

        if matches > 0
          artists = tasteometer['artists']['artist'].map { |a| a['name'] }

          msg << "They have both listened to #{enumerate artists}."
        end

        m.reply msg
      rescue Lastfm::ApiError => e
        m.reply e.message.gsub(/\s+/, ' ').strip
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong."
      end

      def set_username(m, username)
        nickname = m.user.authname || m.user.nick
        
        user = Models::User.first_or_create :nickname => nickname
        user.update :lastfm_name => username

        m.reply "You have been registered as #{username}."
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong."
      end

      def get_username(m, username = nil)
        user = @client.user.get_info :user => find_lastfm_username(m, username)

        m.reply "#{username || m.user.nick} is #{user['name']} on Last.fm and" +
          " has #{user['playcount']} scrobbles (#{user['url']})."
      rescue Lastfm::ApiError => e
        m.reply e.message.gsub(/\s+/, ' ').strip
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong."
      end

      def similar(m, artist = nil)
        if artist.nil?
          track = @client.user.get_recent_tracks(
            :user => find_lastfm_username(m),
            :limit => 1
          )

          track = track.first if track.is_a? Array

          if track.nil?
            m.reply "Please provide an artist name."
            return
          end

          artist = track['artist']['content']
        end

        similar = @client.artist.get_similar :artist => artist, :limit => 5
        artists = similar[1..-1].map { |a| a['name'] }

        if artists[1].empty?
          m.reply "#{similar.first} is too unique to be similar to others."
        else
          m.reply "#{similar.first} is similar to #{enumerate artists}." 
        end
      rescue Lastfm::ApiError => e
        m.reply e.message.gsub(/\s+/, ' ').strip
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong."
      end

      def artist(m, artist_name = nil)
        if artist_name.nil?
          track = @client.user.get_recent_tracks(
            :user => find_lastfm_username(m),
            :limit => 1
          )

          track = track.first if track.is_a? Array

          if track.nil?
            m.reply "Please provide an artist name."
            return
          end

          artist_name = track['artist']['content']
        end

        artist = @client.artist.get_info(
          :artist => artist_name, :username => find_lastfm_username(m)
        )

        message = artist['name']

        if artist['tags'].has_key? 'tag'
          tags = artist['tags']['tag'][0..2].map { |tag| tag['name'] }

          message << " makes #{enumerate tags} music " unless tags.empty?
        end

        message << "and has #{artist['stats']['listeners']} listeners."

        if artist['stats'].has_key? 'userplaycount'
          message << " You scrobbled them #{artist['stats']['userplaycount']}" +
          " times."
        end

        m.reply message
      rescue Lastfm::ApiError => e
        m.reply e.message.gsub(/\s+/, ' ').strip
      rescue => e
        bot.loggers.error e.message
        m.reply "Something went wrong."
      end

    private

      def find_lastfm_username(m, username = nil)
        nickname = m.user.authname || m.user.nick
        user     = Models::User.first :nickname => username || nickname

        if user.nil? || user.lastfm_name.nil?
          if username.nil?
            m.user.notice "You haven't registered yet, #{m.user.nick} is " +
              "assumed as your last.fm username. You can register with " +
              "!setusername <last.fm username>."

            return nickname
          elsif User(username).channels.one? { |c| c == m.channel }
            m.user.notice "#{username} hasn't registered yet, #{username} is " +
              "assumed as his/her last.fm username."
          end

          return username
        end
        
        return user.lastfm_name
      end

      def enumerate(array)
        if array.size > 1
          "#{array[0..-2].join ', '} and #{array.last}"
        elsif array.size == 1
          array.first
        end
      end
    end
  end
end
