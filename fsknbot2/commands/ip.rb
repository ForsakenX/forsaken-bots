class IrcCommandManager
  def self.ip
    if user = IrcUser.find_by_nick(@msg.args[0])
      @msg.reply "#{user.nick} => #{user.ip||user.host}"
    end
  end
end
