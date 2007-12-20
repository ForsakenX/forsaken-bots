class GameEvents < Meth::Plugin

  def initialize *args
    super *args
    if @bot.name == 'fskn_bot' || @bot.name == 'krocked'
      setup_messages
      GameModel.event.register("game.started",@game_started)
      GameModel.event.register("game.finished",@game_stopped)
      GameModel.event.register("game.time.out",@game_timeout)
    end
    if @bot.name == 'fskn_bot'
      GameModel.event.register("game.started",@topic_change)
      GameModel.event.register("game.finished",@topic_change)
    end
  end

  def cleanup
    GameModel.event.unregister("game.started",@game_started)
    GameModel.event.unregister("game.finished",@game_stopped)
    GameModel.event.unregister("game.time.out",@game_timeout)
    if @bot.name == 'fskn_bot'
      GameModel.event.unregister("game.started",@topic_change)
      GameModel.event.unregister("game.finished",@topic_change)
    end
  end

  def setup_messages

    @topic_change = Proc.new{|game|
      next unless channel = Irc::Channel.channels['#forsaken']
      games = GameModel.games.length
      gstring = "#{games} Games | "
      channel.topic = channel.topic.gsub(/^ *[0-9]+ Games \| /,gstring)
      @bot.send_data "TOPIC #forsaken :#{channel.topic}\n"
    }
  
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
  
  end

end
