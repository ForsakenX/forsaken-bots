IrcCommandManager.register ['host','die'], 'host a game' do |m|

    return m.reply("You don't have an ip number...") if m.from.ip.nil?

    if Game.find(m.from.ip)
      return m.reply("Waiting for you to start...")
    end

    if game = Game.create(:host => m.from,:version => m.args.join(' '))
      m.reply "Waiting for game to start:  #{game.url}"
    end

end
