IrcCommandManager.register 'unhost', 'removes your game' do |m|

  return if m.from.ip.nil?

  Game.destroy(m.from.ip)

  m.reply "Your game has been removed..."

end
