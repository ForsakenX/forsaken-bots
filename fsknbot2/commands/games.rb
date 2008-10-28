class IrcCommandManager
  def self.games

    return @msg.reply("Read the topic...") unless Game.length > 0

    hosts = []
    waiting = []
    Game.games.each do |game|
      unless game.start_time
        time_left = game.timeout - (Time.now - game.created_at).to_i
        time = GamesCommand::seconds_to_clock(time_left)
        waiting << "{ "+
                   "#{game.hostmask} "+
                   "version: (#{game.version}) "+
                   "times out in: (#{time}) "+
                   "}"
        next
      end
      time = GamesCommand::seconds_to_clock( Time.now - game.start_time )
      hosts << "{ "+
               "#{game.hostmask} version: (#{game.version}) "+
               "since #{game.start_time.strftime('%I:%M:%S')} "+
               "runtime #{time}"+
               " }"
    end

    @msg.reply "Hosting: #{hosts.join(', ')}" if hosts.length > 0
    @msg.reply "Waiting: #{waiting.join(', ')}" if waiting.length > 0

  end
end

module GamesCommand
  def self.seconds_to_clock seconds
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

