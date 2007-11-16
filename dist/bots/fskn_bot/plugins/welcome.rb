class Welcome < Meth::Plugin

  def initialize *args
    super *args
    setup
  end

  def setup
    if @bot.name == 'fskn_bot'
      @welcome_message = Proc.new{|m|
        # dont send to my self
        next if m.user.nick.downcase == @bot.nick.downcase
        welcome_message = File.read(File.expand_path("#{DIST}/bots/#{$bot}/db/welcome_message.txt")).read
        # send the message
        @bot.say(m.user.nick, welcome_message)
      }
      @bot.event.register("irc.message.join",@welcome_message)
    end
  end

  def cleanup
    @bot.event.unregister("irc.message.join",@welcome_message) if @bot.name == 'fskn_bot'
  end

end
