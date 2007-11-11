class EventCallbacks < Meth::Plugin

  def initialize *args
    super *args
    if @bot.name == 'fskn_bot' || @bot.name == 'krocked'
      setup_messages
      GameModel.event.register("game.started",@game_started)
      GameModel.event.register("game.finished",@game_stopped)
      GameModel.event.register("game.time.out",@game_timeout)
      @bot.event.register("irc.message.join",@welcome_message)
    end
  end

  def cleanup
    GameModel.event.unregister("game.started",@game_started)
    GameModel.event.unregister("game.finished",@game_stopped)
    GameModel.event.unregister("game.time.out",@game_timeout)
    @bot.event.unregister("irc.message.join",@welcome_message)
  end

  def setup_messages
    @game_started = Proc.new{|game|
      @bot.channels.each do |name,channel|
        @bot.say name, "#{game.hostmask} has started a game!"
      end
    }
  
    @game_stopped = Proc.new{|game|
      @bot.channels.each do |name,channel|
        @bot.say name, "#{game.hostmask} has stopped hosting..."
      end
    }
  
    @game_timeout = Proc.new{|game|
      @bot.channels.each do |name,channel|
        @bot.say name, "#{game.hostmask} has been removed...  "+
                  "This is because it never started within timely fashion."
      end
    }
  
    @welcome_message = Proc.new{|m|
      next if m.user.nick.downcase == @bot.nick.downcase
      next if @bot.name == 'krocked'
      @bot.say m.user.nick, ""+
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
         "Messages on GameSpy are automatically coppied over to here, "+
         "but to be covert sending messages to GameSpy requires you to prefix a semi-colon. "+
         "For example, '; this message would make it to GameSpy!' "+
         "I can do more and more things for you everyday! "+
         "For more information ask me for help.  "+
         "If you have any great ideas for me just shoot an email over to fskn.methods@gmail.com! "+
         "NOTE: If your not registered/identified you can't send private messages!  "+
         "To register you can follow the instructions @ "+
         "http://chino.homelinux.org/~daquino/forsaken/chat/"
    }
  end

end
