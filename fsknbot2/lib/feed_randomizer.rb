
class FeedRandomizer

	attr_reader :url

	def initialize url, length=nil
		@url = url
		@seen = []
		@items = []
		@length = length
	end

	def random

		# update item list if empty
		if @items.length < 1
			@seen = []
			if @length
				@items = Feed.new(@url).items.select do |item|
					item.description.length < @length
				end
			else
				@items = Feed.new(@url).items
			end
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

