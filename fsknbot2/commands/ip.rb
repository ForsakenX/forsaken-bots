IrcCommandManager.register 'ip', "Pongs Back!" do |m|
  if user = IrcUser.find_by_nick(m.args.first)
    m.reply "#{user.nick} => #{user.ip||user.host}"
  else
    m.reply "Unknown user"
  end
end
