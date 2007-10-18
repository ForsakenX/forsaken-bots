puts "Running fskn_games.rb"

puts "Loading models"
Dir["#{DIST}/fskn_games/models/*.rb"].each do |m|
  if FileTest.executable?(m)
    require m
    puts "Loaded: #{File.basename(m)}"
  end
end

puts "Registering Game Events"
GameModel.event.register("game.started",Proc.new{|game|
  nick = @nick.gsub(/^_[0-9]*_/,"_#{GameModel.games.length}_")
  send_nick(nick)
  @channels.each do |name,channel|
    say name, "#{game.hostmask} has started a game!"
  end
})
GameModel.event.register("game.finished",Proc.new{|game|
  nick = @nick.gsub(/^_[0-9]*_/,"_#{GameModel.games.length}_")
  send_nick(nick)
  @channels.each do |name,channel|
    say name, "#{game.hostmask} has stopped hosting..."
  end
})

