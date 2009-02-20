
IrcCommandManager.register 'chatter',
	"chatter [random|qotd]"

IrcCommandManager.register 'chatter' do |m|
	case command = m.args.shift
	when nil,'random'
		m.reply Chatter.random 
	when 'fortune'
		m.reply Chatter.fortune
	when 'qotd'
		m.reply Chatter.qotd 
	else
		m.reply IrcCommandManager.help[ 'chatter' ]
	end
end

$run_observers << Proc.new {
	minute = 60
	hour = 60 * minute
	EM::PeriodicTimer.new( hour ) do
	  IrcConnection.privmsg "#forsaken", Chatter.random
	end
}

class Chatter
class << self

	@@chatters = [ :fortune, :qotd ]

	def random
		self.send @@chatters[ rand( @@chatters.length ) ]
	rescue Exception
		$!
	end

	def fortune
		(`/usr/games/fortune`||"").gsub(/\s/,' ')
	end

	def qotd # 4 random quotes daily
		@qotd ||= FeedRandomizer.new(
			"http://feeds2.feedburner.com/quotationspage/qotd"
		)
		@qotd.random
	end

end
end

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

		# return the random quote
		"#{item.title}: #{item.description}"

	end

end

