require "timeout"

module Cinch
  module Plugins
    class Preview
      HANDLERS = Hash.new

      include Cinch::Plugin

      attr_reader :ignored_domains

      def initialize(*args)
        super

        @ignored_domains = Array(config[:ignored_domains])
      end

      listen_to :message, :method => :listen

      def listen(m)
        msg = m.message.gsub ' www.', 'http://www.'

        URI.extract(msg, ["http", "https"])
          .map  { |uri| preview_for URI.parse(uri) }
          .each { |preview| m.reply preview }
      end

    private

      # 1. Tries a custom handler first.
      # 2. Tries the default handler if custom handler returns false or raises
      #    an exception.
      def preview_for(uri)
        domain = uri.host.split(".").last(2).join "."

        return if ignored_domains.include? domain

        default = Thread.new { default_preview uri }

        if HANDLERS.key? domain 
          preview = custom_preview(uri, HANDLERS[domain])
        end

        if preview
          default.exit
        else
          preview = default.value
        end

        return preview
      rescue Timeout::Error
        nil
      rescue => e
        bot.loggers.exception e and nil
      end

      def custom_preview(uri, handler)
        Timeout.timeout(5) { handler.call uri }
      end

      def default_preview(uri)
        Timeout.timeout(5) { HANDLERS[:default].call uri }
      end
    end
  end
end