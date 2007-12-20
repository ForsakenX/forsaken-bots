class Mode < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("mode",self)
  end
  def help(m=nil, topic=nil)
    "mode [channel|nick] => Interface to irc mode command..."
  end
  def command m
    unless target = m.params.shift
      m.reply m.channel.mode
      return
    end
    if target =~ /^#/
      if channel = @bot.channels[target]
        m.reply channel.mode
      else
        m.reply "I'm not not in that channel..."
      end
    else
      if user = m.channel.users.detect{|u|u.nick == target}
        m.reply user.flags
      else
        m.reply "User not found in channel..."
      end
    end
  end
end