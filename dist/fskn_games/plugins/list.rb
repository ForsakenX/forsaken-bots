class List < Meth::Plugin

  def help m
    "list => Prints list of games..."
  end

  def command m
    games = GameModel.games
    unless games.length > 0
      m.reply "There are currently no games..."
      return
    end
    hostmasks = []
    games.each do |game|
      hostmasks << game.hostmask
    end
    m.reply hostmasks.join(', ')
  end

end

