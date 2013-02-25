require 'urban_dictionary'

module Cinch
  module Plugins
    class Slang
      include Cinch::Plugin

      set :plugin_name, 'slang'
      set :help, 'Usage: !slang <word>.'

      match /slang (.+)/i, :method => :slang

      def slang(m, word)
        definition = UrbanDictionary.define(word).entries.first.definition
        m.reply definition.gsub("\r", '. ')
      end
    end
  end
end
