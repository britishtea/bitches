require "cgi"
require "open-uri"
require "nokogiri"

module Cinch
  module Plugins
    class Preview
      class Title
        class SAX < Nokogiri::XML::SAX::Document
          def characters(string)
            if @in_title == true
              @title.nil? ? @title = string : @title << string
            end
          end

          def start_element(name, attrs = [])
            @in_title, @title = true, nil if name == "title"
          end

          def end_element(name)
            if @in_title
              @in_title = false
              throw(:title, @title)
            end
          end
        end

        def initialize
          @parser  = Nokogiri::HTML::SAX::Parser.new SAX.new, 'utf-8'
          @headers = { "User-Agent" => "bitches/#{RUBY_VERSION}",
                       :redirect    => true }
        end

        def call(uri)
          open(uri, @headers) { |file| extract_title file }
        rescue OpenURI::HTTPError => e # a 404.
          extract_title e.io
        end

      private
        
        def extract_title(file)
          return unless file.content_type =~ /text\/html/

          title = catch(:title) do
            @parser.encoding = file.charset
            @parser.parse file.read
          end

          return if String(title).empty?

          cleaned_title = title.gsub(/\s+/, ' ').strip
          cleaned_title.force_encoding file.charset unless file.charset.nil?
          title         = "Title: #{CGI.unescape_html cleaned_title}"

          file.status[0] == "200" ? title : title + " [#{file.status.join " "}]"
        end
      end

      HANDLERS[:default] = Title.new
    end
  end
end
