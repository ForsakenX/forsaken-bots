#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test.lib'
require 'rss_watch' # incase not executable

# setup the test database
test_db = "#{ROOT}/db/rss_watch_test_db.yaml"
#FileUtils.rm test_db, :force => true
RssWatch.db = File.expand_path test_db

def add url
	feed = RssWatch.add( url )
	puts "Feed, '#{feed.title}' added, "+
             "cached #{feed.items.length} items..."
end

#
# Add Entries (url only get loaded once)
#

add "http://feeds2.feedburner.com/quotationspage/qotd"

#
# Detect Changes
#

RssWatch.update_feeds

