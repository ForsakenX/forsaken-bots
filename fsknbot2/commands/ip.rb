class IrcCommandManager
  def self.ip
    if user = IrcUser.find_by_nick(@msg.args[0])
      if user.ip
        @msg.reply "#{user.nick} => #{user.ip}"
      else
        @msg.reply "unaffiliated/#{user.nick}"
      end
    else
      @msg.reply "Unknown User"
    end
  end
end
