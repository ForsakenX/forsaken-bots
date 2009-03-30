IrcCommandManager.register 'games', 'list games' do |m|
  GamesCommand.run.split("\n").each{|l| m.reply l }
end

class GamesCommand
  class << self

    def run

      return "No games...  " unless Game.length > 0
    
      hosts = []
      waiting = []
      Game.games.each do |game|
        if game.start_time
          hosts << parse_host(game)
        else
          waiting << parse_waiting(game)
        end
      end
    
      output  = ""
      output += "Hosting: #{hosts.join(', ')}" if hosts.length > 0
      output += "Waiting: #{waiting.join(', ')}" if waiting.length > 0

      output
    end

    def parse_waiting game
      time_left = game.timeout - (Time.now - game.created_at).to_i
      time = seconds_to_clock(time_left)
      "{ #{game.to_s} times out in: (#{time}) }"
    end

    def parse_host game
      time = seconds_to_clock( Time.now - game.start_time )
      "{ "+
         "#{game.to_s} "+
         "started at: #{game.start_time.strftime('%I:%M:%S')} "+
         "runtime #{time} "+
       "}"
    end
    
    def seconds_to_clock seconds
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
end

