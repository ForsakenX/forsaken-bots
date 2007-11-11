# removes a game from list
class Unhost < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("unhost",self)
  end

  def help m
    "unhost => Removes your game from the list..."
  end

  # remove a game
  def command m
    if m.source.ip == nil
      m.reply "You don't have an ip number..."
      return
    end
    user = m.source
    unless game = GameModel.find(user.ip)
      m.reply "You dont have a game up..."
      return
    end
    game.destroy
    m.reply "Your game has been removed..."
  end

end
