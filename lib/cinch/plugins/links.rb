require 'httparty'

module Cinch
  module Plugins
    class Links
      include Cinch::Plugin
      
      LINKS = {
        :tumblr   => 'http://whatindie.tumblr.com/',
        :gallery  => 'http://indie-gallery.herokuapp.com/',
        :stats    => 'http://zhaan.org/ircstats/indie/',
        :collage  => '2013: https://what.cd/collages.php?id=19215, ' + 
          '2012: https://what.cd/collages.php?id=19213',
        :facebook => 'https://www.facebook.com/indievidualradio',
        :twitter  => 'https://twitter.com/indievidualme',
        :mixtapes => 'http://www.mixcloud.com/indievidual/'
      }
      
      set :plugin_name, 'links'
      set :help, "Usage: !link[s] [(#{LINKS.keys.join '|'})]."
      
      match /link(s)?$/i,         :group => :links, :method => :all_links
      match /link(?:s)? (\S+)?/i, :group => :links, :method => :one_link
      match /mixtape$/i,                            :method => :mixtape
      
      def all_links(m)
        LINKS.each do |key, url| 
          m.user.notice "#{key.to_s.capitalize}: #{url}"
        end
      end
      
      def one_link(m, option)
        if option == 'mixtape'
          mixtape m
        elsif LINKS.has_key? option.to_sym
          m.reply "#{option.capitalize}: #{LINKS[option.to_sym]}"
        else
          m.user.notice "I don't know of any links for #{option}."
        end
      end

      def mixtape(m)
        url = 'http://api.mixcloud.com/indievidual/cloudcasts/'
        mixtape = HTTParty.get(url, :format => :json)['data'].first

        m.reply "#{mixtape['name']}: #{mixtape['url']}"
      end
    end
  end
end
