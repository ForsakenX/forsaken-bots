IrcCommandManager.register 'games', 'list games' do |m|
  GamesCommand.run.split("\n").each{|l| m.reply l }
end

class GamesCommand
  class << self

    def run
      return "No games...  " unless Game.length > 0
      output = []
      Game.games.each do |game|
	      time = seconds_to_clock( Time.now - game.start_time )
	      output << "{ "+
        	 "#{game.to_s} "+
	         "started at: #{game.start_time.strftime('%I:%M:%S')} "+
        	 "runtime #{time} "+
	       "}"
      end
      "Games: #{output.join(', ')}"
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

