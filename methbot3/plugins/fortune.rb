
IrcCommandManager.register 'fortune' do |m|
  m.reply FortuneCommand.run
end

$run_observers << Proc.new {
	EM::PeriodicTimer.new( 60*60*30 ) do
	  IrcConnection.privmsg "#forsaken", FortuneCommand.run
	end
}

class FortuneCommand
  def self.run
    (`/usr/games/fortune`||"").gsub(/\s/,' ')
  end
end

