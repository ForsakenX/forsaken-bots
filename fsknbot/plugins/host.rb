class Host < Irc::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("host",self)
    @bot.command_manager.register("!host",self)
  end

  def command m
    if m.command == "host"
      return m.reply("Please use !host")
    end
    if m.params.length < 1
      return m.reply(help)
    end
    if m.source.ip == nil
      m.reply "You don't have an ip number..."
      return
    end
    if game = GameModel.create({:user => m.source,
                                :version => m.params.join(' ')})
      m.reply "Waiting for game to start:  "+
              "#{game.hostmask} "+
              "version: (#{game.version})"
    end
  end

  def help m=nil, topic=nil
    "!host <version> => "+
      "Starts a game in waiting mode.  "+
      "Notifies everyone when the game starts and ends."
  end

end
