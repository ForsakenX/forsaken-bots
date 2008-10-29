IrcCommandManager.register 'ip', "Pongs Back!" do |m|
  if user = IrcUser.find_by_nick(m.args[0])
    m.reply "#{user.nick} => #{user.ip||user.host}"
  end
end
