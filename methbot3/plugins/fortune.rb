
IrcCommandManager.register 'fortune' do |m|
  m.reply FortuneCommand.run
end

$run_observers << Proc.new {
	minute = 60
	hour = 60 * minute
	EM::PeriodicTimer.new( hour * 2 ) do
	  IrcConnection.privmsg "#forsaken", FortuneCommand.run
	end
}

class FortuneCommand
  def self.run
    (`/usr/games/fortune`||"").gsub(/\s/,' ')
  end
end

