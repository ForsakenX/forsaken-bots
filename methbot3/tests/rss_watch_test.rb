#!/usr/bin/ruby

# boot strap environment
ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"
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

# forsaken / 6dof photos
#add "http://picasaweb.google.com/data/feed/base/user/mr.danielaquino/albumid/5192437501857810545?alt=rss&kind=photo&hl=en_US"

# daquino's shared google reader items
#add "http://www.google.com/reader/public/atom/user%2F07134456291971328108%2Fstate%2Fcom.google%2Fbroadcast"

# daquino's temp photos
#add "http://picasaweb.google.com/data/feed/base/user/mr.danielaquino/albumid/5302860549662082145?alt=rss&kind=photo&hl=en_US"

#
# Detect Changes
#

class IrcConnection
  def self.privmsg target, msg
    puts "privmsg: target => #{target}, msg => #{msg}"
  end
end

RssWatch.update_feeds

