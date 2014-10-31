# Encoding: utf-8
require "cgi"

module Bitches
  module Helpers
    extend self

    # movie - An IMDb::Movie.
    def imdb_preview(movie)
      preview  = movie.title true
      preview += " (#{movie.year})"                         if movie.year
      preview += " - #{movie.length} min"                   if movie.length
      preview += " - #{("★" * movie.rating).ljust 10, "☆"}" if movie.rating
      preview += " - #{movie.plot}"                         if movie.plot
      preview += " [#{movie.genres.join ", "}]"             if movie.genres

      return preview
    end

    # release - A Hash.
    def whatcd_torrentgroup_preview(release)
      if release["group"]["categoryName"] == "Music"
        preview = whatcd_music_torrentgroup release
      else
        preview = whatcd_general_torrentgroup release
      end

      return CGI.unescapeHTML preview
    end

    # thread - A Hash.
    def whatcd_thread_preview(thread)
      forum  = thread["forumName"]
      title  = thread["threadTitle"]
      extras = thread["locked"] ? "🔒" : ""

      return CGI.unescapeHTML "Forums > #{forum} > #{title} #{extras}".strip
    end

    def whatcd_user_preview(user)
      username = user["username"]
      rank     = user["personal"]["class"]
      upload   = filesize user["stats"]["uploaded"].to_i
      download = filesize user["stats"]["downloaded"].to_i
      ratio    = user["stats"]["ratio"]

      "#{username} (#{rank}) - ↑#{upload} ↓#{download} (#{ratio})"
    end

    def whatcd_request_preview(request)
      title  = request["title"]
      year   = request["year"]
      votes  = request["voteCount"]
      bounty = filesize request["totalBounty"]
      status = request["isFilled"] ? "filled" : "unfilled"

      "#{title} (#{year}) [#{bounty} / #{status}]"
    end

    def youtube_preview(video)
      rating   = ("★" * video.rating.average.ceil).ljust 5, "☆"
      duration = Time.at(video.duration).gmtime.strftime "%R:%S"
      duration = duration[3..-1] if duration.start_with? "00"

      "#{video.title} [#{duration}] - #{rating}"
    end

  private

    def whatcd_music_torrentgroup(release)
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

    def whatcd_general_torrentgroup(release)
      "#{release["group"]["categoryName"]}: #{release["group"]["name"]}"
    end

    def filesize(bytes)
      conversions = { "TB" => 1024 ** 4, "GB" => 1024 ** 3, "MB" => 1024 ** 2,
                      "KB" => 1024,      "B"  => 1 }

      format, size = conversions.find { |_,size| bytes >= size }

      return "#{(bytes / size.to_f).round 2} #{format}"
    end
  end
end