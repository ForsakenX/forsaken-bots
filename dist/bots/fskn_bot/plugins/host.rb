class Host < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("host",self)
  end

  def command m
    if game = GameModel.find(m.source.ip)
      m.reply "You already have a game listed..."
      return
    end
    if game = GameModel.create({:user => m.source})
      m.reply "Game created: #{game.hostmask}"
    end
  end

  def help m
    "host => "+
      "Creates a game.  "+
      "I will test your host port continously until you have a game up.  "+
      "At which time everyone will be notified.  "+
      "Every 30 seconds I'll make sure your still hosting.  "+
      "When you are no longer hosting, I'll remove your game and notify everyone."
  end

end
