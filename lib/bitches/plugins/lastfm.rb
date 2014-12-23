require "lastfm"
require "bonehead"

module Bitches
  module Plugins
    class LastFM
      include Cinch::Plugin

      NOT_REGISTERED = "You are not registered. Use !setusername <last.fm " \
        "username> to register."
      
      set :plugin_name => "last",
          :help        => "Usage: see http://goo.gl/5Ar4QU."
      
      match /np$/i,       :group => :np, :method => :np_self
      match /np (\S+)$/i, :group => :np, :method => :np_other

      def initialize(*args)
        super

        warn "No Last.fm API key given."    unless config[:api_key]
        warn "No Last.fm API secret given." unless config[:api_key]

        @client = Lastfm.new config[:api_key], config[:api_secret]
      end

      def np_self(m)
        unless lastfm_name_for m.user
          m.user.notice NOT_REGISTERED
          m.user.notice "\"#{m.user}\" is assumed to be your Last.fm username."
        end

        m.reply now_playing(m.user, m.user.nick)
      rescue => e
        handle_exceptions m, e
      end

      def np_other(m, nick)
        m.reply now_playing(nick, nick)
      rescue => e
        handle_exceptions m, e
      end

      # nick         - A nickname String.
      # display_name - A display_name String.
      def now_playing(nick, display_name)
        track = try do
          @client.user.get_recent_tracks(
            :user => lastfm_name_for(User(nick)) || nick,
            :limit => 1
          )
        end

        # Some weirdness in the lastfm library. It returns an Array when a
        # track is nowplaying, otherwise it returns a track Hash.
        track = track.first if track.is_a? Array

        if track.nil?
          msg = "#{display_name} isn't playing anything right now."
        elsif track.key? "nowplaying"
          artist, title = track['artist']['content'], track['name']
          msg = "#{display_name} is now playing #{artist} - #{title}."
        elsif Time.at(track["date"]["uts"].to_i).between? Time.now - 600, Time.now
          artist, title = track['artist']['content'], track['name']
          msg = "#{display_name} last played #{artist} - #{title}."
        else
          msg = "#{display_name} hasn't scrobbled in a while."
        end

        return msg
      end


      match /co(?:mpare)? (\S+)$/i,       :group => :co, :method => :co_self
      match /co(?:mpare)? (\S+) (\S+)$/i, :group => :co, :method => :co_other
      match /coham$/i,                    :group => :co, :method => :coham

      def co_self(m, nick)
        unless lastfm_name_for m.user
          m.user.notice NOT_REGISTERED
          m.user.notice "\"#{m.user}\" is assumed to be your last.fm username."
        end

        m.reply compare(m.user, nick)
      rescue => e
        handle_exceptions m, e
      end

      def co_other(m, nick_one, nick_two)
        m.reply compare(nick_one, nick_two)
      rescue => e
        handle_exceptions m, e
      end

      def coham(m)
        m.reply compare("moham", m.user)
      rescue => e
        handle_exceptions m, e
      end

      # one - A Cinch::User or last.fm username String.
      # two - A Cinch::User or last.fm username String.
      def compare(one, two)
        tasteometer = try do
          @client.tasteometer.compare(
            :type1 => 'user', :value1 => lastfm_name_for(User one) || one,
            :type2 => 'user', :value2 => lastfm_name_for(User two) || two,
            :limit => 5
          )
        end

        score   = Float(tasteometer['score']) * 100
        matches = Integer(tasteometer['artists']['matches'])
        msg     = "#{one} and #{two} are #{score.round 2}% alike."

        if matches > 0
          artists = tasteometer['artists']['artist'].map { |a| a['name'] }
          msg << " They have both listened to #{enumerate artists}."
        end

        return msg
      end


      match /setuser(?:name)? (\S+)/i, :method => :set_username

      def set_username(m, lastfm_name)
        nickname = m.user.authname || m.user.nick
        
        user = Models::User.first_or_create :nickname => nickname

        # This will raise sometimes.
        if @client.user.get_info(:user => lastfm_name)
          user.update :lastfm_name => lastfm_name
          m.reply "You have been registered as #{lastfm_name}."
        else
          m.reply "There is no #{lastfm_name} on Last.fm."
        end
      rescue => e
        handle_exceptions m, e
      end
     

      match /user (\S+)$/i, :method => :user

      def user(m, lastfm_name)
        m.reply info_for(lastfm_name, lastfm_name)
      rescue => e
        handle_exceptions m, e
      end

      # nick - A Cinch::User.
      def info_for(lastfm_name, display_name)
        info = try { @client.user.get_info :user => lastfm_name }

        if info.nil?
          return "Last.fm does not know anyone called \"#{lastfm_name}\"."
        else
          return "#{display_name} is #{info['name']} on Last.fm and has " \
            "#{info['playcount']} scrobbles (#{info['url']})."
        end
      end


      match /getuser(?:name)?$/i,       :group => :get, :method => :get_self
      match /getuser(?:name)? (\S+)$/i, :group => :get, :method => :get_other

      def get_self(m)
        lastfm_name = lastfm_name_for m.user

        if lastfm_name
          m.reply info_for lastfm_name, m.user.nick
        else
          m.reply NOT_REGISTERED
        end
      rescue => e
        handle_exceptions m, e
      end

      def get_other(m, nick)
        lastfm_name = lastfm_name_for User(nick)
        
        if lastfm_name
          m.reply info_for lastfm_name, nick
        else
          m.reply "#{nick} is not registered."
        end
      rescue => e
        handle_exceptions m, e
      end
      

      match /similar$/i,      :group => :similar, :method => :similar_current
      match /similar (.+)$/i, :group => :similar, :method => :similar_to

      def similar_current(m)
        m.reply similarity(current_artist_for m.user)
      rescue => e
        handle_exceptions m, e
      end

      def similar_to(m, artist)
        m.reply similarity(artist)
      rescue => e
        handle_exceptions m, e
      end

      def similarity(artist)
        similar = try do 
          @client.artist.get_similar :artist => artist,
                                     :limit  => 5,
                                     :autocorrect => 1
        end

        artists = similar[1..-1].map { |a| a["name"] }

        if artists[1].empty?
          msg = "#{similar.first} is too unique to be similar to others."
        else
          msg = "#{similar.first} is similar to #{enumerate artists}." 
        end

        return msg
      end

      match /artist$/i,      :group => :artist, :method => :artist_current
      match /artist (.+)$/i, :group => :artist, :method => :artist

      def artist_current(m)
        m.reply artist_info(current_artist_for m.user)
      rescue => e
        handle_exceptions m, e
      end

      def artist(m, artist)
        m.reply artist_info(artist)
      rescue => e
        handle_exceptions m, e
      end

      def artist_info(artist_name)
        artist = try do 
          @client.artist.get_info :artist => artist_name,
                                  :autocorrect => 1
        end

        msg = "#{artist['name']} "

        if artist['tags'].has_key? 'tag'
          tags = artist['tags']['tag'][0..2].map { |tag| tag['name'] }
 
          msg << "is tagged as #{enumerate tags} and " unless tags.empty?
        end

        msg << "has #{artist['stats']['listeners']} listeners."
        msg << " #{artist['url']}"

        return msg
      end

    private

      def try
        Bonehead.insist 3, Lastfm::ApiError do |try|
          sleep 0.1 if try > 0
          yield if block_given?
        end
      end

      def handle_exceptions(m, e)
        case e
        when Lastfm::ApiError
          m.reply "Error from Last.fm: #{e.message.gsub(/\s+/, ' ').strip}."
        else
          bot.loggers.exception e
          m.reply "Something went wrong."
        end
      end

      # user - A Cinch::User.
      def lastfm_name_for(user)
        result = Models::User.first(
          :conditions => ['LOWER(nickname) = ?', 
          (user.authname || user.nick).downcase]
        )
        
        return result.lastfm_name unless result.nil?
      end

      # user - A Cinch::User.
      def current_artist_for(user)
        track = try do
          @client.user.get_recent_tracks :user => lastfm_name_for(user),
                                         :limit => 1
        end

        # Some weirdness in the lastfm library. It returns an Array when a
        # track is nowplaying, otherwise it returns a track Hash.
        track = track.first if track.is_a? Array

        return track['artist']['content'] unless track.nil?
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
