
class FeedRandomizer

	attr_reader :url

	def initialize url
		@url = url
		@seen = []
		@items = []
	end

	def random

		# update item list if empty
		if @items.length < 1
			@seen = []
			@items = Feed.new(@url).items
		end

		# no items found?
		return false if @items.length < 1

		# get random item
        	item = @items[ rand( @items.length ) ]

		# move item to seen list
		@seen << item
		@items.delete item

		# return item
		item

	end

end

