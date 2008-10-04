class Launcher < Irc::Plugin
  def pre_init
    @bot.command_manager.register("!launcher",self)
    @db = "#{ROOT}/db/launcher.link"
  end
  def url
    File.read(@db).gsub("\n","")
  end
  def command m
    message = "You can download the new launcher "+
              "from the following url: { #{url} }."
    m.reply message
  end
end
