# removes a game from list
class Unhost < Meth::Plugin

  def help m
    "unhost => Removes your game from the list..."
  end

  # remove a game
  def command m
    user = m.source
    unless game = GameModel.find(user.ip)
      m.reply "You dont have a game up..."
      return
    end
    game.destroy
    m.reply "Your game has been removed..."
  end

end
