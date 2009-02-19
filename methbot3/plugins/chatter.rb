
IrcCommandManager.register 'chatter' do |m|
  m.reply Chatter.random
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
		FortuneCommand.run
	end

	def qotd
		QOTD.random
	end

end
end

