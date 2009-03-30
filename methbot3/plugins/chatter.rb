
class Chatter
class << self

	@@chatters = [ :random, :fortune, :offensive, :limerick, :qotd, :fqotd, :jotd, :wotd ]
	def chatters; @@chatters; end

	def random
		self.send @@chatters[ rand( @@chatters.length ) ]
	rescue Exception
		puts_error __FILE__,__LINE__
		$!
	end

	# should we add ability to add fortunes ?

	@@fortune_modes = %w{offensive off art astrology atheism black-humor bofh-excuses computers cookie debian definitions disclaimer drugs education ethnic food fortunes goedel hphobia humorists kids knghtbrd law limerick linux linuxcookie literature love magic mario.anagramas mario.computadores mario.gauchismos mario.geral mario.palindromos mario.piadas medicine men-women misandry miscellaneous misogyny news paradoxum people perl pets platitudes politics privates racism religion riddles science sex songs-poems spam sports startrek translate-me vulgarity wisdom work zippy}

	def fortune_modes; @@fortune_modes; end

	def fortune args=[]
		# -a include all even offensive fortunes
		opts = ['-a']
		# -n length of fortune
		opts << "-sn 220"
		# offensive mode only
		if args.delete("offensive") || args.delete("off")
			opts << " -o"
		end
		# db to use
		while db = args.shift
			unless @@fortune_modes.include? db
				return "Unknown database: #{db}"
			end
			opts << " #{db}"
		end
		# remove certain db's
#		opts << " 0% ascii-art"
		# join
		opts = opts.join(' ')
puts opts
		off_dir = "/usr/share/games/fortunes/off"
		(`cd #{off_dir}; fortune #{opts} 2>&1`||"").gsub(/\s+/,' ')
	end

	def offensive args=[]
		fortune ['off'] + args
	end

	def limerick args=[]
		fortune ['off','limerick'] + args
	end

	def qotd args=[] # random quotes daily
		@qotd ||= FeedRandomizer.new(
			"http://www.brainyquote.com/link/quotefu.rss",
			200
		)
		item = @qotd.random
		"#{item.title}: #{item.description}"
	end

	def fqotd args=[]  # funny quote of the day
		@fqotd ||= FeedRandomizer.new(
			"http://feeds2.feedburner.com/quotationspage/qotd",
			200

		)
		item = @fqotd.random
		"#{item.title}: #{item.description}"
	end

	def jotd args=[]  # joke of the day
		@jotd ||= FeedRandomizer.new(
			"http://www.comedycentral.com/rss/jokes/"+
			"indexcached.jhtml?partner=rssMozilla",
			200

		)
		item = @jotd.random
		"#{item.title}: #{item.description}"
	end

	def wotd args=[]  # 1 word of the day
		url = "http://feeds.reference.com/DictionarycomWordOfTheDay"
		feed = Feed.new( url )
		"#{feed.title} => #{feed.items.first.description}"
	end

end
end

IrcCommandManager.register 'chatter',
	"chatter [#{Chatter.chatters.join('|')}]\n" +
	"chatter fortune [<mode>...] => Possible Modes: "+
	"[#{Chatter.fortune_modes.join('|')}]"

IrcCommandManager.register 'chatter' do |m|
	command = m.args.shift
	if command.nil? || command.empty?
		m.reply Chatter.random
		next
	end
	command = command.to_sym
	if Chatter.chatters.include? command
		m.reply Chatter.send command, m.args
	else
		m.reply IrcCommandManager.help[ 'chatter' ]
	end
end

$run_observers << Proc.new {
	minute = 60
	hour = 60 * minute
	EM::PeriodicTimer.new( 2 * hour ) do
	  IrcConnection.privmsg "#forsaken", Chatter.random
	end
}

