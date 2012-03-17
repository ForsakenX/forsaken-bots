class Chatter
class << self

	@@chatters = [ :desc, :random, :fortune, :wotd ]
	def chatters; @@chatters; end

	@@randoms = []
	def random count=0
		chatter = @@chatters[ rand( @@chatters.length ) ]
		puts "Chatter Random: " + chatter.to_s
		if chatter == :fortune
			mode = @@fortune_modes[rand(@@fortune_modes.length)]
			output = self.send chatter, [mode]
		else 
			@@randoms = [] if @@randoms.length > 50
			output = self.send chatter
			output = false if @@randoms.detect{|x|x==output}
			@@randoms << output
		end
		return random count+=1 unless output
		output
	rescue Exception
		puts_error __FILE__,__LINE__
		"chatter error: "+ $!
	end

	def desc args=[]
		words = File.readlines "#{ROOT}/db/words"
		GoogleCommand.desc words[rand(words.length)]
	end

	# should we add ability to add fortunes ?

	@@fortune_modes = %w{art ascii-art bofh-excuses calvin chalkboard chucknorris computers cookie debian definitions drugs dubya education ethnic familyguy firefly food fortunes futurama gentoo-dev gentoo-forums goedel hitchhiker homer humorists humorix-misc humorix-stories kernelcookies kids knghtbrd law linux linuxcookie literature love magic medicine men-women miscellaneous news off osfortune paradoxum people perl pets platitudes politics powerpuff pqf riddles science smac songs-poems SP sports startrek starwars strangelove tao translate-me wisdom work zippy zx-error}

	def fortune_modes; @@fortune_modes; end

	def fortune args=[]
		opts = []
		# -n length of fortune
		opts << "-sn 220"
		# db to use
		while db = args.shift
			unless @@fortune_modes.include? db
				return "Unknown database: #{db}"
			end
			opts << " #{db}"
		end
		opts = opts.join(' ')
		puts "Chatter Fortune options: "+ opts.to_s
		off_dir = "/usr/share/fortune"
		(`fortune #{opts} 3>&1`||"").gsub(/\s+/,' ')
	end

	def wotd args=[]  # 1 word of the day
		url = "http://feeds.reference.com/DictionarycomWordOfTheDay"
		feed = Feed.new( url )
		item = feed.items.first
		"#{feed.title} => #{item.description}"
	rescue Exception
		puts_error __FILE__, __LINE__
		"WOTD Feed Error"
	end

end
end

IrcCommandManager.register 'chatter',
	"chatter [#{Chatter.chatters.join(', ')}]\n" +
	"chatter fortune [<mode>...] => Possible Modes: "+
	"[#{Chatter.fortune_modes.join(', ')}]"

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
	EM::PeriodicTimer.new( 6 * hour ) do
	  IrcConnection.privmsg "#forsaken", Chatter.random
	end
}

