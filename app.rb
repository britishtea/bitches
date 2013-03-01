require 'cinch'
require 'cinch/extensions/authentication'
require 'cinch/plugins/identify'
require 'cinch/plugins/imdb'
require 'cinch/plugins/media'
require 'cinch/plugins/lastfm'
require 'cinch/plugins/links'
require 'cinch/plugins/whatcd'
require 'cinch/plugins/big_brother'
require 'cinch/plugins/slang'
require 'cinch/plugins/recommend'
require 'cinch/plugins/weather'
require 'cinch/plugins/title'
require 'cinch/plugins/google'

# Interal: Checks if the environment is production.
#
# Returns a Boolean.
def production?
  ENV['ENVIRONMENT'] == 'production'
end

# Set up DataMapper
require 'data_mapper'
require 'bitches/models'

DataMapper.setup :default, ENV['DATABASE_URL']
DataMapper.finalize
DataMapper.auto_upgrade!

# Set up the Cinch::Bot
bot = Cinch::Bot.new do
  configure do |c|
    c.server   = ENV['SERVER']
    c.port     = ENV['PORT'] || 6667
    c.password = ENV['PASSWORD']
    c.nick     = ENV['NICKNAME']
    c.user     = ENV['NICKNAME']
    c.channels = production? ? ['#indie', '#indie-ops'] : ['#indie-test']
    c.ssl.use  = true if ENV.has_key? 'SSL'

    c.authentication = Cinch::Configuration::Authentication.new
    c.authentication.strategy = :channel_status
    c.authentication.level    = :h
    c.authentication.channel  = production? ? '#indie' : '#indie-test'
    
    c.plugins.plugins = [Cinch::Plugins::IMDb, Cinch::Plugins::Links, 
      Cinch::Plugins::Slang, Cinch::Plugins::Recommend, Cinch::Plugins::Weather,
      Cinch::Plugins::Title, Cinch::Plugins::Google]
    
    c.plugins.plugins << Cinch::Plugins::Identify
    c.plugins.options[Cinch::Plugins::Identify] = {
      :password => ENV['NICKSERV_PASSWORD'] || '',
      :type     => :nickserv,
    }

    c.plugins.plugins << Cinch::Plugins::LastFM
    c.plugins.options[Cinch::Plugins::LastFM] = {
      :api_key    => ENV['LASTFM_KEY'],
      :api_secret => ENV['LASTFM_SECRET']
    }
    
    c.plugins.plugins << Cinch::Plugins::Media
    c.plugins.options[Cinch::Plugins::Media] = {
      :url           => 'http://indie-gallery.herokuapp.com/',
      :channels      => ['#indie', '#indie-test'],
      :ignored_hosts => ['images.4chan.org', 'https://fbcdn-sphotos-c-a.akamaihd.net/'],
      :ignored_tags  => [/nsfw/i, /nsfl/i, / personal/i, /ignore/i]
    }

    c.plugins.plugins << Cinch::Plugins::What
    c.plugins.options[Cinch::Plugins::What] = {
      :username => ENV['WHATCD_USERNAME'],
      :password => ENV['WHATCD_PASSWORD']
    }

    c.plugins.plugins << Cinch::Plugins::BigBrother
    c.plugins.options[Cinch::Plugins::BigBrother] = {
      :channel => production? ? '#indie-ops' : '#indie-test'
    }
  end

  on :message, "!help" do |m|
    m.reply "See http://goo.gl/ZFy1V."
  end

  on :message, "!ping" do |m|
    m.reply 'pong'
  end
end

# Configure loggers
bot.loggers.level = :info

# Quit with an appropriate message
Signal.trap('SIGINT') { bot.quit 'Bye' }

# Start the Cinch::Bot
bot.start
