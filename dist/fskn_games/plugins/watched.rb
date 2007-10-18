class Watched < Meth::Plugin

  def help m
    "watched => Display list of hosts being watched..."
  end

  def command m
    games = GameModel.games
    unless games.length > 0
      m.reply "There are currently no hosts being watched..."
      return
    end
    hostmasks = []
    games.each do |game|
      hostmasks << game.hostmask
    end
    m.reply hostmasks.join(', ')
  end

end

