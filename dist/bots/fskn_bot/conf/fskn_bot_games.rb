puts "Loading fskn_bot_games"

GameModel.event.register("game.started",Proc.new{|game|
  nick = @nick.gsub(/^_[0-9]*_/,"_#{GameModel.games.length}_")
  send_nick(nick)
})

GameModel.event.register("game.finished",Proc.new{|game|
  nick = @nick.gsub(/^_[0-9]*_/,"_#{GameModel.games.length}_")
  send_nick(nick)
})

