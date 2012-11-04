# require 'bundler/setup'
# Bundler.require :default
# Bundler.require ENV['ENVIRONMENT'].to_sym
require 'cinch'
require 'data_mapper'

require 'cinch/plugins/choons'
require 'cinch/plugins/identify'
require 'cinch/plugins/imdb'
require 'cinch/plugins/media'
require 'cinch/plugins/fun'
require 'cinch/plugins/links'
require 'cinch/plugins/whatcd'

# Interal: Checks if the environment is production.
#
# Returns a Boolean.
def production?
  ENV['ENVIRONMENT'] == 'production'
end

# Set up DataMapper
DataMapper.setup :default, ENV['DATABASE_URL']

require 'bitches/models'

DataMapper.finalize
DataMapper.auto_upgrade!

# Set up the Cinch::Bot
bot = Cinch::Bot.new do
  configure do |c|
    c.nick     = production? ? 'bitches' : 'testes'
    c.user     = 'bitches'
    c.server   = 'irc.what-network.net'
    c.channels = production? ? ['#indie'] : ['#indie-test']
    
    c.plugins.plugins = [
      Cinch::Plugins::Choons,
      Cinch::Plugins::Identify,
      Cinch::Plugins::IMDb,
      Cinch::Plugins::Media,
      Cinch::Plugins::Fun,
      Cinch::Plugins::Links,
      Cinch::Plugins::What
    ]
    
    c.plugins.options[Cinch::Plugins::Identify] = {
      :password => ENV['NICKSERV_PASS'] || '',
      :type     => :nickserv,
    }
    
    c.plugins.options[Cinch::Plugins::Media] = {
      :url           => 'http://indie-gallery.herokuapp.com/',
      :channel       => '#indie',
      :ignored_hosts => ['images.4chan.org', 'https://fbcdn-sphotos-c-a.akamaihd.net/'],
      :ignored_tags  => [/nsfw/i, /nsfl/i, / personal/i, /ignore/i]
    }
    
    c.plugins.options[Cinch::Plugins::Choons] = { :channel => '#indie' }

    c.plugins.options[Cinch::Plugins::What] = {
      :username => ENV['WHATCD_USERNAME'],
      :password => ENV['WHATCD_PASSWORD']
    }
    
    DataMapper.auto_upgrade!
  end

  on :message, "!help" do |m|
    m.reply "See http://goo.gl/ZFy1V"
  end

  # on :message, /^!what .+/ do |m|
  #   m.reply "!what unfortunately doesn't work anymore due to an IP block on the Heroku server(s) that bitches runs on."
  # end
end

# Configure loggers
bot.loggers.level = :info

# Quit with an appropriate message
Signal.trap('TERM') { bot.quit 'Bye' }

# Start the Cinch::Bot
bot.start
