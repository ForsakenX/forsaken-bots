class Fortune < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("fortune",self)
    @bot.event.register("irc.message.privmsg",Proc.new{|m|
      privmsg m
    })
  end
  def help(m=nil, topic=nil)
    "fortune => Displays a fortune."
  end
  def privmsg m
    if m.message =~ /fortune/i 
      command m
    end
  end
  def command m
    begin
      m.reply `fortune`.gsub(/[\n\t ]+/,' ')
    rescue Exception
      m.reply "#{$!}"
    end
  end
end
