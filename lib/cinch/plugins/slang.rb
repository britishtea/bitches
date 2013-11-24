require 'urban_dictionary'

module Cinch
  module Plugins
    class Slang
      include Cinch::Plugin

      set :plugin_name, 'slang'
      set :help, 'Usage: !slang <word>.'

      match /slang (.+)/i, :method => :slang

      def slang(m, word)
        results = UrbanDictionary.define(word)

        if results.nil?
          m.reply "No definition for \"#{word}\"."
        else
          definition       = results.entries.first.definition
          clean_definition = definition.gsub("\r", '. ').gsub(/\s+/, ' ')

          m.reply "#{word.capitalize}: #{clean_definition}" 
        end
      end
    end
  end
end
