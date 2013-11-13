require 'lastfm'
require 'retryable'

module Cinch
  module Plugins
    class LastFM
      include Cinch::Plugin
      include Retryable
      
      set :plugin_name, 'last'
      set :help, 'Usage: see http://goo.gl/ZFy1V.'
      
      match /np(?: (\S+))?/i,                   :method => :now_playing
      match /co(?:mpare)? (\S+)(?: (\S+))?/i,   :method => :compare
      match /setuser(?:name)? (\S+)/i,          :method => :set_username
      match /(?:getusername|user)(?: (\S+))?/i, :method => :get_username
      match /similar(?: (.+))?/i,               :method => :similar
      match /artist(?: (.+))?/i,                :method => :artist

      def initialize(*args)
        super

        @client = Lastfm.new config[:api_key], config[:api_secret]

        # Set up callbacks for Retryable
        @finally = Proc.new do |e, handler|
          if e.is_a? Lastfm::ApiError
            handler[:message].reply e.message.gsub(/\s+/, ' ').strip
          else
            handler[:message].reply "Something went wrong."
          end
        end
      end

      def now_playing(m, username = nil)
        retryable :finally => @finally do |handler|
          handler[:message] = m

          track = @client.user.get_recent_tracks(
            :user => find_lastfm_username(m, username),
            :limit => 1
          )

          # Some weirdness in the lastfm library. It returns an Array when a
          # track is nowplaying, otherwise it returns a track Hash.
          track  = track.first if track.is_a? Array

          if track.nil?
            msg = "#{username || m.user.nick} isn't playing anything right now."
          elsif !track.has_key? 'nowplaying'
            # Last.fm's API is wacky. Sometimes it says the user isn't playing,
            # while in fact they are. We're manually checking wether or not it's
            # likely that the user is currently playing the last scrobbled track
            scrobble_start = Time.parse track['date']['content']
            artist         = track['artist']['content']

            track_info     = @client.track.get_info(
              :mbid   => track['mbid'],
              :artist => artist,
              :track  => track['name']
            )

            max = scrobble_start + (Integer(track_info['duration']) / 1000)

            if Time.now < max
              msg = "#{username || m.user.nick} is now playing #{artist} - " +
              "#{track['name']}."
            else
              msg = "#{username || m.user.nick} isn't playing anything right " +
                "now."
            end
          else
            artist = track['artist']['content']
            msg    = "#{username || m.user.nick} is now playing #{artist} - " +
              "#{track['name']}."
          end

          m.reply msg
        end
      end

      def compare(m, one, two = nil)
        retryable :finally => @finally do |handler|
          handler[:message] = m

          user     = Models::User.first :conditions => ['LOWER(nickname) = ?',
            one.downcase]
          username = user.nil? || user.lastfm_name.nil? ? one : user.lastfm_name

          tasteometer = @client.tasteometer.compare(
            :type1 => 'user', :value1 => username,
            :type2 => 'user', :value2 => find_lastfm_username(m, two),
            :limit => 5
          )

          score   = Float(tasteometer['score']) * 100
          matches = Integer(tasteometer['artists']['matches'])
          msg     = "#{one} and #{two || m.user.nick} are #{score.round 2}% " +
            "alike."

          if matches > 0
            artists = tasteometer['artists']['artist'].map { |a| a['name'] }
            msg << " They have both listened to #{enumerate artists}."
          end

          m.reply msg
        end
      end

      def set_username(m, username)
        nickname = m.user.authname || m.user.nick
        
        user = Models::User.first_or_create :nickname => nickname
        user.update :lastfm_name => username

        m.reply "You have been registered as #{username}."
      end

      def get_username(m, username = nil)
        retryable :finally => @finally do |handler|
          handler[:message] = m

          user = @client.user.get_info(
            :user => find_lastfm_username(m, username)
          )

          m.reply "#{username || m.user.nick} is #{user['name']} on Last.fm " +
            "and has #{user['playcount']} scrobbles (#{user['url']})."
        end
      end

      def similar(m, artist = nil)
        retryable :finally => @finally do |handler|
          handler[:message] = m

          artist ||= get_current_artist m

          similar = @client.artist.get_similar(:artist => artist, :limit => 5, 
            :autocorrect => 1)
          artists = similar[1..-1].map { |a| a['name'] }

          if artists[1].empty?
            m.reply "#{similar.first} is too unique to be similar to others."
          else
            m.reply "#{similar.first} is similar to #{enumerate artists}." 
          end
        end
      end

      def artist(m, artist_name = nil)
        retryable :finally => @finally do |handler|
          handler[:message] = m

          artist_name ||= get_current_artist m

          artist = @client.artist.get_info(:artist => artist_name, 
            :username => find_lastfm_username(m), :autocorrect => 1)

          message = "#{artist['name']} "

          if artist['tags'].has_key? 'tag'
            tags = artist['tags']['tag'][0..2].map { |tag| tag['name'] }
 
            message << "is tagged as #{enumerate tags} and " unless tags.empty?
          end

          message << "has #{artist['stats']['listeners']} listeners."
          message << " #{artist['url']}"

          m.reply message
        end
      end

    private

      def find_lastfm_username(m, username = nil)
        nickname = m.user.authname || m.user.nick
        user     = Models::User.first :conditions => ['LOWER(nickname) = ?', 
          (username || nickname).downcase]

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

      def get_current_artist(m)
        track = @client.user.get_recent_tracks(
          :user => find_lastfm_username(m),
          :limit => 1
        )

        track = track.first if track.is_a? Array

        raise Lastfm::ApiError, "Please provide an artist." if track.nil?

        return track['artist']['content']
      end
    end
  end
end
