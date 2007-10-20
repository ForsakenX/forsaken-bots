# get status of running games
class Status < Meth::Plugin

  def help m
    "status => Displays status on running games..."
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
      unless game.hosting
        waiting << game
      end
      seconds = (Time.now - game.start_time).to_i
      minutes = seconds / 60; seconds = seconds % 60
      hours   = minutes / 60; minutes = minutes % 60
      host = []
      host << game.hostmask + " has been playing for " 
      host << "#{hours} hours " if hours
      host << "#{minutes} minutes " if minutes
      host << "#{seconds} seconds " if seconds
      hosts << "( #{host} )"
    }
    m.reply "There are #{hosts.length} games up: #{hosts.join(', ')}"
    m.reply "Still waiting for the following games to start: #{waiting.join(', ')}" if waiting.length > 0
  end

end

