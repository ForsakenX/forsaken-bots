
IrcCommandManager.register 'fortune' do |m|
  m.reply FortuneCommand.run
end

class FortuneCommand
  def self.run
    (`/usr/games/fortune`||"").gsub(/\s/,' ')
  end
end

