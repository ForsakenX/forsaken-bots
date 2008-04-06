class GameEvents < Meth::Plugin

  include DirectPlay

  def initialize *args
    super *args
    setup_messages
    GameModel.event.register("game.started",@game_started)
    GameModel.event.register("game.finished",@game_stopped)
    GameModel.event.register("game.time.out",@game_timeout)
    GameModel.event.register("game.started",@topic_change)
    GameModel.event.register("game.finished",@topic_change)
    @every_30 = EM::PeriodicTimer.new(30.seconds) {
      @game_checker.call(nil)
    }
    @every_60 = EM::PeriodicTimer.new(60.seconds) {
      # just in case clean up the topic
      @topic_checker.call(nil)
    }
  end

  def cleanup
    GameModel.event.unregister("game.started",@game_started)
    GameModel.event.unregister("game.finished",@game_stopped)
    GameModel.event.unregister("game.time.out",@game_timeout)
    GameModel.event.unregister("game.started",@topic_change)
    GameModel.event.unregister("game.finished",@topic_change)
    @every_30.cancel if @every_30
    @every_60.cancel if @every_60
  end

  def setup_messages

    @game_checker = Proc.new{|game|

      # get forsaken channel
      channels = Irc::Channel.channels
      next unless channels.has_key?("#forsaken") 
      channel = channels["#forsaken"]

      # list of users
      users = channel.users.select{|u|
        # not in ignore list
        next if @bot.ignored.include?(u.nick.downcase)
        # has a non nil ip
        u.ip
      }
  
      # compact by unique ip addresses
      users.each do |user|
        users.each do |u|
          users.delete(user) if (user != u) && (user.ip == u.ip)
        end
      end
  
      # have resulsts ?
      next unless users.length > 0
  
      # check the users
      find_hosts(users){|results|

        # add hosts to game list
        results[:hosts].each do |user|
          next if GameModel.find(user.ip)
          game = GameModel.create({:user => user})
        end
  
        # fix up the topic
        @topic_checker.call(nil)

      }
    }

    @topic_checker = Proc.new{|game|
      channels = Irc::Channel.channels
      next unless channels.has_key?("#forsaken") 
      channel = channels["#forsaken"]
      games = GameModel.games.length
      current = channel.topic.split(' ')[0]
      if current != games.to_s
        topic = channel.topic.gsub(/^[0-9]+/,games.to_s)
        @bot.send_data "TOPIC #forsaken :#{topic}\n"
      end
    }
  
    @game_started = Proc.new{|game|
      @bot.msg "#forsaken", "#{game.hostmask} has started a game!"
    }
  
    @game_stopped = Proc.new{|game|
      @bot.msg "#forsaken", "#{game.hostmask} has stopped hosting..."
    }
  
    @game_timeout = Proc.new{|game|
      @bot.msg "#forsaken", "#{game.hostmask} has been removed...  "+
                            "This is because it never started within timely fashion."
    }
  
  end

end
