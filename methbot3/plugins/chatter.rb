
class Chatter
class << self

	@@chatters = [ :fortune, :qotd, :fqotd, :jotd, :fotd, :wotd ]
	def chatters; @@chatters; end

	def random
		self.send @@chatters[ rand( @@chatters.length ) ]
	rescue Exception
		puts_error __FILE__,__LINE__
		$!
	end

	def fortune
		(`/usr/games/fortune`||"").gsub(/\s/,' ')
	end

	def qotd # random quotes daily
		@qotd ||= FeedRandomizer.new(
			"http://www.brainyquote.com/link/quotefu.rss"
		)
		item = @qotd.random
		"#{item.title}: #{item.description}"
	end

	def fqotd # funny quote of the day
		@fqotd ||= FeedRandomizer.new(
			"http://feeds2.feedburner.com/quotationspage/qotd"
		)
		item = @fqotd.random
		"#{item.title}: #{item.description}"
	end

	def jotd # joke of the day
		@jotd ||= FeedRandomizer.new(
			"http://www.comedycentral.com/rss/jokes/"+
			"indexcached.jhtml?partner=rssMozilla"
		)
		item = @jotd.random
		"#{item.title}: #{item.description}"
	end

	def fotd # fact of the day
		@fotd ||= FeedRandomizer.new(
			"http://www.b4u.com/rss/en_facts.xml"
		)
		item = @fotd.random
		"#{item.title}: #{item.description}"
	end

	def wotd # 1 word of the day
		url = "http://feeds.reference.com/DictionarycomWordOfTheDay"
		feed = Feed.new( url )
		"#{feed.title} => #{feed.items.first.description}"
	end

end
end

IrcCommandManager.register 'chatter',
	"chatter [#{Chatter.chatters.join('|')}]"

IrcCommandManager.register 'chatter' do |m|
	command = m.args.shift
	if command.nil? || command.empty?
		m.reply IrcCommandManager.help[ 'chatter' ]
		next
	end
	command = command.to_sym
	if Chatter.chatters.include? command
		m.reply Chatter.send command
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

