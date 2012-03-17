
IrcCommandManager.register 'rsswatch', 'rsswatch <url>' do |m|
  next m.reply "Unauthorized" unless m.from.authorized?
  next m.reply "Missing Url" if m.args.length < 1
  begin
    feed = RssWatch.add m.args.first
  rescue Exception
    puts_error __FILE__, __LINE__
    next m.reply "Feed Error: #{$!.slice(0,50)}"
  end
  next m.reply "Feed, '#{feed.title}' added, "+
               "cached #{feed.items.length} items..."
end

$run_observers << Proc.new {
        interval = 60*6 # every minute
        EM::PeriodicTimer.new( interval ) do
		RssWatch.update_feeds
        end
}

require 'yaml'
require 'feed'
class RssWatch
  class << self

    @@send_queue = []

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

    def update_feeds
#      puts "-- Updating RssWatch Feeds"
      load_feeds
      @@feeds.each do |url,links|
	begin
#		puts "-- checking #{url}"
		feed = Feed.new url 
	        next unless feed.items.length > 0
	        feed.items.reverse.each do |item|
	          next if links.include? item.link
	          links << item.link
	          # shrink url
	          #tiny = TinyUrl.new(item.link).tiny || item.link
	          tiny = item.link
	          #msg = "#{feed.title}: #{item.title} #{tiny} "
	          msg = "#{item.title} #{tiny} "
	          #msg += Url.describe_link( item.link )
	          @@send_queue << msg        
	          puts "-- Found item #{item.title}"
	        end
#	        puts "-- Feed links: #{feed.items.length}"
	rescue Exception
			puts "ERROR ::::::: file parsing feed at: #{url}"
	    puts_error __FILE__, __LINE__
	end
      end
      puts "-- Done Updating RssWatch Feeds"
      save_feeds
      IrcConnection.privmsg $channels, @@send_queue.shift
    rescue Exception
			puts "ERROR ::::::::::   update_feeds "
	    puts_error __FILE__, __LINE__
    end

  end
end

