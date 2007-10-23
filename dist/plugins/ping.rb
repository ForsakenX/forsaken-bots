class Ping < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("ping",self)
  end
  def help m
    "ping => Reply's with 'pong'"
  end
  def command m
    m.reply "pong"
  end
end
