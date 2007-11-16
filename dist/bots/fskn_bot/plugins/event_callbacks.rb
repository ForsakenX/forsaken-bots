class EventCallbacks < Meth::Plugin

  def initialize *args
    super *args
    if @bot.name == 'fskn_bot' || @bot.name == 'krocked'
      setup_messages
      GameModel.event.register("game.started",@game_started)
      GameModel.event.register("game.finished",@game_stopped)
      GameModel.event.register("game.time.out",@game_timeout)
    end
  end

  def cleanup
    GameModel.event.unregister("game.started",@game_started)
    GameModel.event.unregister("game.finished",@game_stopped)
    GameModel.event.unregister("game.time.out",@game_timeout)
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
  
  end

end
