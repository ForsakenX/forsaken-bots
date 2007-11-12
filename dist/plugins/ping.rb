class Ping < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("ping",self)
  end
  def help(m=nil, topic=nil)
    "ping => Writes everyones name on one line.  "+
    "Normally their client will produce a notification."
  end
  def command m
    m.reply m.channel.users.map{|user| user.nick}.join(" ")
  end
end
