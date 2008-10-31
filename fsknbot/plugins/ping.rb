class Ping < Irc::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("!ping",self)
  end
  def command m
    m.reply "(FsknBot1) pong"
  end
end
