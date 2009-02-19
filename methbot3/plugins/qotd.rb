
IrcCommandManager.register ['qotd','quote'] do |m|
  m.reply QOTD.random
end

class QOTD
class << self

	# 4 random quotes daily
	@@url = "http://feeds2.feedburner.com/quotationspage/qotd"

	@@seen = []
	@@items = []

	def random

		# update item list if empty
		if @@items.length < 1
			@@seen = []
			@@items = Feed.new(@@url).items
		end

		# no items found?
		return false if @@items.length < 1

		# get random item
        	item = @@items[ rand( @@items.length ) ]

		# move item to seen list
		@@seen << item
		@@items.delete item

		# return the random quote
		"#{item.title}: #{item.description}"

	end

end
end

