IrcCommandManager.register 'ip', "ip <user>: shows ip of user." do |m|
  if user = m.args.first.nil? ? m.from : IrcUser.find_by_nick(m.args.first)
    m.reply "#{user.nick} => #{user.ip||user.host}"
  else
    m.reply "Unknown user"
  end
end
