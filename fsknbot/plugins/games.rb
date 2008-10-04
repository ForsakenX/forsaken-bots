# get games of running games
class Games < Irc::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("!games",self)
  end

  def help m=nil, topic=nil
    "games => Displays games on running games..."
  end

  def command m
    games = GameModel.games
    unless games.length > 0
      m.reply "There are currently no games..."
      return
    end
    hosts = []
    waiting = []
    games.each { |game|
      unless game.start_time
        time_left = GameModel.wait_timeout - (Time.now - game.created_at).to_i
        time = time_to_human(time_left)
        waiting << "{ "+
                   "#{game.hostmask} "+
                   "version: (#{game.version}) "+
                   "times out in: (#{time}) "+
                   "}"
        next
      end
      time = time_to_human( Time.now - game.start_time )
      hosts << "{ "+
               "#{game.hostmask} version: (#{game.version}) "+
               "since #{game.start_time.strftime('%I:%M:%S')} "+
               "runtime #{time}"+
               " }"
    }
    m.reply "Hosting: #{hosts.join(', ')}" if hosts.length > 0
    m.reply "Waiting: #{waiting.join(', ')}" if waiting.length > 0
  end

  def time_to_human seconds
      seconds = seconds.to_i
      minutes = seconds / 60; seconds = seconds % 60
      hours   = minutes / 60; minutes = minutes % 60
      output  = ""
      output += "#{hours}:" if hours > 0
      output += "#{minutes}:" if minutes > 0
      output += "#{seconds}"
      output += " seconds" if (hours+minutes) < 1
      output
  end

end

