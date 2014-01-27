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
          return false unless uri.path == "/torrents.php"

          release = @client.fetch :torrentgroup, :id => uri.query[/\d+/]

          if release["group"]["categoryName"] == "Music"
            msg = create_music_preview(release)
          else
            msg = create_general_preview(release)
          end

          return CGI.unescapeHTML(msg)
        end

      private

        def create_music_preview(release)
          artists = release["group"]["musicInfo"]["artists"]

          if artists.size == 1
            artist = artists.first["name"]
          elsif artists.size.between?(1, 4)
            last   = artists.pop["name"]
            artist = "#{artists.map { |a| a["name"] }.join ", "} & #{last}"
          else
            artist = "Various Artists"
          end
          
          name      = release["group"]["name"]
          year      = release["group"]["year"]
          encodings = release['torrents'].map { |t| t['encoding'] }.uniq

          "#{artist} - #{name} (#{year}) [#{encodings.join ' / '}]"
        end

        def create_general_preview(release)
          "#{release["group"]["categoryName"]}: #{release["group"]["name"]}"
        end
      end

      HANDLERS["what.cd"] = WhatCD.new
    end
  end
end