# Encoding: utf-8
require "imdb"

module Cinch
  module Plugins
    class Preview
      class IMDb
        def call(uri)
          return false unless uri.path.start_with? "/title/tt"
          
          create_preview Imdb::Movie.new(uri.path[9..15])
        end

      private

        def create_preview(movie)
          preview  = movie.title true
          preview += " (#{movie.year})"                         if movie.year
          preview += " - #{movie.length} min"                   if movie.length
          preview += " - #{("★" * movie.rating).ljust 10, "☆"}" if movie.rating
          preview += " - #{movie.plot}"                         if movie.plot
          preview += " [#{movie.genres.join ", "}]"             if movie.genres
          preview += " - #{movie.url}"

          return preview
        end
      end

      HANDLERS["imdb.com"] = IMDb.new
    end
  end
end
