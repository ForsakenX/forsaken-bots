#!/usr/bin/ruby

ROOT = File.dirname(__FILE__) + "/../"

require "#{ROOT}/config/environment"

#require "#{ROOT}/lib/feed"

def handle_feed url
	puts '*'*50
	feed = Feed.new( url )
	puts feed.title
	puts feed.link
	puts feed.items.first.title
	puts feed.items.first.link
end

# pics
handle_feed "http://picasaweb.google.com/data/feed/base/user/mr.danielaquino/albumid/5192437501857810545?alt=rss&kind=photo&hl=en_US"

# google reader atom feed
handle_feed "http://www.google.com/reader/public/atom/user%2F07134456291971328108%2Fstate%2Fcom.google%2Fbroadcast"

