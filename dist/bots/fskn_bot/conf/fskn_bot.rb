puts "Registering Game Events"

GameModel.event.register("game.started",Proc.new{|game|
  channels.each do |name,channel|
    say name, "#{game.hostmask} has started a game!"
  end
})

GameModel.event.register("game.finished",Proc.new{|game|
  channels.each do |name,channel|
    say name, "#{game.hostmask} has stopped hosting..."
  end
})

@event.register("irc.message.join",Proc.new{|m|
  next if m.user.nick.downcase == @nick.downcase
  say m.user.nick, ""+
     "Hello, I am the forsaken game manager.  "+
     "I help manage and collect information on games.  "+
     "Some of my features include: "+
       "displaying a list of games and their status; "+
       "detecting if someone in the channel is hosting or playing.  "+
     "To Host a game simply say host whenever you see me.  "+
     "You can ask me for status on games too.  "+
     "At a quick glance you can tell how many games are running by my name. "+
     "For more information ask me for help."
})

