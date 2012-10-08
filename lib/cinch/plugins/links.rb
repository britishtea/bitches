module Cinch
  module Plugins
    class Links
      include Cinch::Plugin
      
      LINKS = {
        :tumblr   => 'http://whatindie.tumblr.com/',
        :gallery  => 'http://indie-gallery.herokuapp.com/',
        :stats    => 'http://zhaan.org/ircstats/indie/',
        :collage  => 'https://what.cd/collages.php?id=13264 or https://ssl.what.cd/collages.php?id=13264',
        :facebook => 'https://www.facebook.com/indievidualradio',
        :twitter  => 'https://twitter.com/indievidualme',
      }
      
      set :plugin_name, 'links'
      set :help, "Usage: !link[s] [#{LINKS.keys.join ' / '}]"
      
      match /link(s)?$/i,         :group => :links, :method => :all_links
      match /link(?:s)? (\S+)?/i, :group => :links, :method => :one_link
      
      def all_links(m)
        LINKS.each do |key, url| 
          m.user.notice "#{key.to_s.capitalize}: #{url}"
        end
      end
      
      def one_link(m, option)
        if LINKS.has_key? option.to_sym
          m.reply "#{option.capitalize}: #{LINKS[option.to_sym]}"
        else
          m.user.notice "I don't know of any links for #{option}."
        end
      end
    end
  end
end
