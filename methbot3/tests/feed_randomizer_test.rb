#!/usr/bin/ruby
require File.dirname(__FILE__) + '/test.lib'

feeds = [
#"http://www.brainyquote.com/link/quotefu.rss",
#"http://feeds2.feedburner.com/quotationspage/qotd",
"http://www.comedycentral.com/rss/jokes/"+
	"indexcached.jhtml?partner=rssMozilla",
#"http://www.b4u.com/rss/en_facts.xml",
]

limit = 200

100.times do
	feeds.each do |feed|
		item = FeedRandomizer.new( feed, limit ).random
		next unless item
		if item.description.length > limit
			puts "failed"
		end
		print '.'
	end
	puts
end
