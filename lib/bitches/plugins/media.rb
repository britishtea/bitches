require "cinch/extensions/authentication"
require "net/http"

module Bitches
  module Plugins
    class Media
      include Cinch::Plugin
      include Cinch::Extensions::Authentication
  
      set :plugin_name => "media",
          :help        => "Usage: !delete <url>."
  
      def initialize(*args)
        super

        config[:url]             = URI.parse config[:url]
        config[:ignored_hosts] ||= []
        config[:ignored_tags]  ||= []
      end

      listen_to :message, :method => :listen

      # Public: Adds media to the database
      def listen(m)
        return unless config[:channels].include? m.channel
        return if m.message.start_with? "!del"
        return if config[:ignored_tags].any? { |tag| /#{tag}/i =~ m.message }

        URI.extract(m.message, ["http", "https"])
          .map    { |uri| URI.parse uri }
          .select { |uri| media? uri }
          .each   { |uri| save_media uri, m }
      end

      match /del(?:ete)? (.+)/i, :group => :uris, :method => :delete

      # Public: Removes an offensive link from the database.
      def delete(m, uri)
        return unless authenticated? m

        res = Net::HTTP.start config[:url].host, config[:url].port do |http|
          request = Net::HTTP::Delete.new "/media"
          request.set_form_data "url" => uri, "secret" => config[:secret]

          http.request request
        end

        if res.code == "200"
          m.reply "Done."
        else
          m.reply "Something went wrong."
        end
      rescue => e
        bot.loggers.error e.message
        m.user.notice 'Something went wrong.'
      end

    private

      MEDIA_HOSTS = ["youtube.com", "youtu.be"]

      def media?(uri)
        return false if config[:ignored_hosts].include? uri.host

        uri.host.end_with?(*MEDIA_HOSTS) || 
          open(uri).content_type.start_with?("image")
      end

      def save_media(uri, m)
        Net::HTTP.post_form config[:url] + "/media", 
          "user"    => m.user.authname || m.user.nick,
          "url"     => uri,
          "message" => m.message,
          "secret"  => config[:secret]
      rescue => e
        bot.loggers.exception e
      end
    end 
  end
end
