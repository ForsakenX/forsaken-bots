IrcCommandManager.register 'unhost', 'removes your game' do |m|

  return if m.from.ip.nil?

  game = Game.destroy(m.from.ip)

  m.reply "#{game.name}'s game has been removed."

end
