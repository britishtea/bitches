#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright (c) 2010 Victor Bergoo
# This program is made available under the terms of the MIT License.

require 'nokogiri'
require 'net/http'
require 'cgi'

module Cinch
  module Plugins
    class Title
      include Cinch::Plugin
      
      match /(.*http.*)/, :use_prefix => false, :method => :execute
      
      def execute m, message
        URI.extract message, ["http", "https"] do |uri|
          begin
            next if ignore uri

            title = parse URI(uri)
            
            m.reply "Title: #{title}" unless title.nil?
          rescue URI::InvalidURIError
            next
          end
        end
      rescue => e
        bot.loggers.error e.message
      end

    private

      def parse(uri)
        html  = Nokogiri::HTML Net::HTTP.get_response(uri).body
        title = html.at_xpath('//title')
        
        
        title.nil? ? nil : CGI.unescape_html(title.text.gsub(/\s+/, ' '))
      end
      
      def ignore uri
        ignore = ["jpg$", "JPG$", "jpeg$", "gif$", "png$", "bmp$", "pdf$", "jpe$"]
        ignore.concat(config["ignore"]) if config.key? "ignore"
        
        ignore.each do |re|
          return true if uri =~ /#{re}/
        end
        
        false
      end
    end
  end
end
