#!/usr/bin/ruby

require File.dirname(__FILE__) + '/test.lib'

$screen_width = 75

class Object
	def puts msg=""
	        msg.to_s.scan(/.{0,#{$screen_width}}/m){|chunk|
			clean = chunk.gsub(/\s+/,' ')
                        next if clean.empty?
			super  "* " + clean
	        }
	end
end

def handle_feed url
	feed = Feed.new( url )
        item = feed.items.first
	puts '*'*$screen_width
	puts "Title: #{feed.title}"
        puts "Link: #{feed.link}"
        puts "Description: #{feed.description}"
	puts "One of #{feed.items.length} items:"
	puts "\tTitle: #{item.title}"
        puts "\tLink: #{item.link}"
	puts "\tDescription: #{item.description}"
	puts '*'*$screen_width
end

# quote of the day
handle_feed "http://feeds2.feedburner.com/quotationspage/qotd"

