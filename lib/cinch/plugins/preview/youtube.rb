# Encoding: utf-8
require "bitches/helpers"
require "youtube_it"

module Cinch
  module Plugins
    class Preview
      class YouTube
        def initialize
          @client = YouTubeIt::Client.new
        end

        def call(uri)
          video = @client.video_by uri.to_s

          Bitches::Helpers.youtube_preview video
        rescue OpenURI::HTTPError => e
          false
        end
      end

      YouTube.new.tap do |youtube|
        HANDLERS["youtube.com"] = youtube
        HANDLERS["youtu.be"]    = youtube
      end
    end
  end
end