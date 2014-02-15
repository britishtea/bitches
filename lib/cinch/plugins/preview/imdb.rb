require "bitches/helpers"
require "imdb"

module Cinch
  module Plugins
    class Preview
      class IMDb
        def call(uri)
          return false unless uri.path.start_with? "/title/tt"
          
          Bitches::Helpers.imdb_preview Imdb::Movie.new(uri.path[9..15])
        end
      end

      HANDLERS["imdb.com"] = IMDb.new
    end
  end
end
