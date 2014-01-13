module Bitches
  module Plugins
    class Links
      include Cinch::Plugin
      
      LINKS = {
        "tumblr"   => "http://whatindie.tumblr.com/",
        "gallery"  => "http://indie-gallery.herokuapp.com/",
        "stats"    => "http://zhaan.org/ircstats/indie/",
        "collage"  => "2014: https://what.cd/collages.php?id=21649 " +
                      "2013: https://what.cd/collages.php?id=19215 " + 
                      "2012: https://what.cd/collages.php?id=19213",
        "facebook" => "https://www.facebook.com/indievidualradio",
        "twitter"  => "https://twitter.com/indievidualme",
        "mixtapes" => "http://www.mixcloud.com/indievidual/"
      }
      
      set :plugin_name, "links"
      set :help, "Usage: !link[s] [(#{LINKS.keys.join '|'})]."
      
      match /links$/i,      :group => :links, :method => :all_links
      match /link (\S+)?/i, :group => :links, :method => :one_link
      
      def all_links(m)
        LINKS.each { |key, url| m.user.notice "#{key.capitalize}: #{url}" }
      end
      
      def one_link(m, option)
        if LINKS.has_key? option.downcase
          m.reply "#{option.capitalize}: #{LINKS[option.downcase]}"
        end
      end
    end
  end
end
