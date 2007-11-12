class Hi < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("hi",self)
  end
  def help m=nil, topic=nil
    "hi => Reply's with 'Hey, Whats up!'"
  end
  def command m
    m.reply "Hey, Whats up!"
  end
end
