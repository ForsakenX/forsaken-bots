class TimePlugin < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("time",self)
  end
  def help(m=nil, topic=nil)
    "time => Display the server time."
  end
  def command m
    # Wednesday 11-14-2007 7:51 pm EST
    m.reply "my time: " + Time.now.strftime("%A %m-%d-%Y %I:%M %p %Z")
  end
end
