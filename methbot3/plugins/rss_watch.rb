
IrcCommandManager.register 'rsswatch', 'rsswatch <url>' do |m|
  next m.reply "Unauthorized" unless m.from.authorized?
  next m.reply "Missing Url" if m.args.length < 1
  feed = RssWatch.add m.args.first
  next m.reply "Feed, '#{feed.title}' added, "+
               "cached #{feed.items.length} items..."
end

$run_observers << Proc.new {
        interval = 60 # every minute
        EM::PeriodicTimer.new( interval ) do
		RssWatch.run_updates
        end
}

require 'yaml'
require 'feed'
class RssWatch
  class << self

    @@db = File.expand_path("#{ROOT}/db/rss_watch.yaml")
    def db= db; @@db = db; end

    @@feeds = {} # url => links
    def feeds; @@feeds; end

    def load_feeds
      @@feeds = ((FileTest.exists?(@@db) && YAML.load_file(@@db)) || {})
    end

    def save_feeds
      file = File.open( @@db, 'w+' )
      YAML.dump( @@feeds, file )
      file.close
    end

    def add url
      load_feeds
      feed = Feed.new(url)
      return feed unless @@feeds[ url ].nil? # don't readd
      @@feeds[ url ] = feed.items.map{ |item| item.link }
      save_feeds
      feed
    end

    def run_updates
#      puts "-- Updating RssWatch Feeds"
      load_feeds

      @@feeds.each do |url,links|
	feed = Feed.new url 
        next unless feed.items.length > 0
        feed.items.each do |item|
          next if links.include? item.link
          links << item.link
          msg = "#{feed.title}: new item, #{item.title} => #{item.link}"
#          puts "-- #{msg}"
          IrcConnection.privmsg "#forsaken", msg
        end
      end

      save_feeds
#      puts "-- Done Updating RssWatch Feeds"
    end

  end
end

