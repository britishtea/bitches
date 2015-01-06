require "bitches/helpers"
require "whatcd"

module Cinch
  module Plugins
    class Preview
      class WhatCD
        def initialize
          @client = ::WhatCD::Client.new
          @client.set_cookie ENV["WHATCD_COOKIE"]
        end

        def call(uri)
          case uri.path
            when "/artist.php" then return artist_preview(uri)
            when "/torrents.php" then return torrent_preview(uri)
            when "/forums.php"   then return thread_preview(uri)
            when "/user.php"     then return user_preview(uri)
            when "/requests.php" then return request_preview(uri)
            else                      return false
          end
        rescue ::WhatCD::APIError
          return false
        end

      private

        def artist_preview(uri)
          query = Hash[URI.decode_www_form uri.query]

          return false unless query.key? "id"

          artist = @client.fetch :artist, :id => query["id"]
          
          return Bitches::Helpers.whatcd_artist_preview artist
        end

        def torrent_preview(uri)
          release = @client.fetch :torrentgroup, :id => uri.query[/\d+/]

          return Bitches::Helpers.whatcd_torrentgroup_preview release
        end

        def thread_preview(uri)
          query = Hash[URI.decode_www_form uri.query]

          return false unless query.key? "threadid"

          thread = @client.fetch :forum, :type     => "viewthread",
                                         :threadid => query["threadid"]

          return Bitches::Helpers.whatcd_thread_preview thread
        end

        def user_preview(uri)
          query = Hash[URI.decode_www_form uri.query]
          user  = @client.fetch :user, :id => query["id"]

          return Bitches::Helpers.whatcd_user_preview user
        end

        def request_preview(uri)
          query = Hash[URI.decode_www_form uri.query]
          request = @client.fetch :request, :id => query["id"]

          return Bitches::Helpers.whatcd_request_preview request
        end
      end

      HANDLERS["what.cd"] = WhatCD.new
    end
  end
end
