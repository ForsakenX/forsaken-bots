class Launcher < Meth::Plugin
  def pre_init
    @bot.command_manager.register("launcher",self)
    @bot.command_manager.register("!launcher",self)
    @db = "#{ROOT}/db/launcher.link"
  end
  def url
    File.read(@db).gsub("\n","")
  end
  def command m
    if m.command == "launcher"
      m.reply "Please use !launcher"
    end
    message = "You can download the new launcher "+
              "from the following url: { #{url} }."
    m.reply message
  end
end
