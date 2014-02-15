# Encoding: utf-8
require "bitches/helpers"
require "imdb"

module Cinch
	module Plugins
		class IMDb
			include Cinch::Plugin

      match /imdb tt(\d{7})/i, :group => :imdb, :method => :by_id 
			match /imdb (\d{7})/i,   :group => :imdb, :method => :by_id
			match /imdb (.+)/i,      :group => :imdb, :method => :by_title

			def by_id(m, id)
        movie = Imdb::Movie.new id

        if movie.title.nil?
          m.reply "Couldn't find the movie with id \"#{id}\"."
        else
          m.reply create_movie_preview(movie)
        end
      rescue => e
        handle_exceptions m, e
      end

      def by_title(m, title)
        movies = Imdb::Search.new(title).movies

        if movies.empty?
          m.reply "No results for \"#{title}\""
        else
          m.reply create_movie_preview(movies.first)
        end
      rescue => e
        handle_exceptions m, e
      end

    private

      def handle_exceptions(m, e)
        m.reply "Something went wrong while searching the IMDb."
        bot.loggers.exception e
      end

      def create_movie_preview(movie)
        "#{Bitches::Helpers.imdb_preview movie} - #{movie.url}"
      end
		end
	end
end