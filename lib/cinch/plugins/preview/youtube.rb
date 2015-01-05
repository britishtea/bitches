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
        end
      end

      HANDLERS["youtube.com"] = YouTube.new
      HANDLERS["youtu.be"]    = HANDLERS["youtube.com"]
    end
  end
end
