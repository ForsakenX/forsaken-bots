class IrcCommandManager
  def self.unhost

    return if @msg.from.ip.nil?

    Game.destroy(@msg.from.ip)

    @msg.reply "Your game has been removed..."

  end
end
