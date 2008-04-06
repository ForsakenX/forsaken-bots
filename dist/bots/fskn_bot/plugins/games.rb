# get games of running games
class Games < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("games",self)
  end

  def help m=nil, topic=nil
    "games => Displays games on running games..."
  end

  def command m
    unless m.params.empty?
      return
    end
    games = GameModel.games
    unless games.length > 0
      m.reply "There are currently no games..."
      return
    end
    hosts = []
    waiting = []
    games.each { |game|
      unless game.start_time
        waiting << game.hostmask
        next
      end
      seconds = (Time.now - game.start_time).to_i
      minutes = seconds / 60; seconds = seconds % 60
      hours   = minutes / 60; minutes = minutes % 60
      time = "#{hours}:#{minutes}:#{seconds}"
      hosts << "( "+
               "#{game.hostmask} "+
               "since #{game.start_time.strftime('%I:%M:%S')} "+
               "runtime #{time}"+
               " )"
    }
    m.reply "There are #{hosts.length} games up: #{hosts.join(', ')}"
    m.reply "Still waiting for the following games to start: #{waiting.join(', ')}" if waiting.length > 0
  end

end

