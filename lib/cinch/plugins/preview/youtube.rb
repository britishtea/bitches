# Encoding: utf-8
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

          rating   = ("★" * video.rating.average.ceil).ljust 5, "☆"
          duration = Time.at(video.duration).gmtime.strftime "%R:%S"
          duration = duration[3..-1] if duration.start_with? "00"

          "#{video.title} [#{duration}] - #{rating}"
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