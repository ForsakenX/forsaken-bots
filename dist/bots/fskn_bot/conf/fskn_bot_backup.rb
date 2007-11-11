puts "Loading fskn_bot.rb"

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

GameModel.event.register("game.time.out",Proc.new{|game|
  channels.each do |name,channel|
    say name, "#{game.hostmask} has been removed...  "+
              "This is because it never started within timely fashion."
  end
})

@event.register("irc.message.join",Proc.new{|m|
  next if m.user.nick.downcase == @nick.downcase
  next if @name == 'krocked'
  say m.user.nick, ""+
     "Hello, I am the forsaken bot!  "+
     "Some of my features include: "+
       "helping to manage and collect information on games.  "+
       "displaying a list of games and their status; "+
       "detecting if someone in the channel is hosting or playing; "+
       "linking messages between GameSpy and this channel; "+
       "and way more! "+
     "To know right away how many games are running, "+
       "look for my other name which looks like _n_games, "+
       "where 'n' is the number of games currently playing! "+
     "To get status on current running games just type status! "+
     "To Host a game simply say host!  "+
     "I can do more and more things for you everyday! "+
     "For more information ask me for help.  "+
     "If you have any great ideas for me just shoot an email over to fskn.methods@gmail.com! "+
     "NOTE: If your not registered/identified you can't send private messages!  "+
     "To register you can follow the instructions @ "+
     "http://chino.homelinux.org/~daquino/forsaken/chat/"
})



