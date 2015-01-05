require "bitches/helpers"
require "imdb"

module Cinch
  module Plugins
    class Preview
      HANDLERS["imdb.com"] = proc do |uri|
        if uri.path.start_with? "/title/tt"
          Bitches::Helpers.imdb_preview Imdb::Movie.new(uri.path[9..15])
        else
          false
        end
      end
    end
  end
end
