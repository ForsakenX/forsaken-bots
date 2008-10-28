class IrcCommandManager
  def self.host

    return @msg.reply("You don't have an ip number...") if @msg.from.ip.nil?

    if Game.find(@msg.from.ip)
      return @msg.reply("Waiting for you to start...")
    end

    if game = Game.create(:host => @msg.from,:version => @msg.args.join(' '))
      @msg.reply "Waiting for game to start:  #{game.hostmask} "+
                 "version: (#{game.version})"
    end

  end
end
