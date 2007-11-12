class TimePlugin < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("time",self)
  end
  def help(m=nil, topic=nil)
    "time => Display the server time."
  end
  def command m
    m.reply Time.now
  end
end
