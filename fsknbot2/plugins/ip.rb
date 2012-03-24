IrcCommandManager.register 'ip', "ip <user>: shows ip of user." do |m|
  if user = m.args.first.nil? ? m.from : IrcUser.find_by_nick(m.args.first)
		if user.ip =~ /^unaffiliated/
			m.reply "User #{user.nick} has hidden their ip..."
		else
			m.reply "#{user.nick} (#{user.ip}) #{user.location}"
		end
  else
    m.reply "Unknown user"
  end
end
