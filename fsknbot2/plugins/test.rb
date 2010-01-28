
IrcCommandManager.register 'test',
	"test [user] [port]: Test if player's ports are open.  "+
	"[port] by default is 2300,  " +
	"!test [port] = test your own game on given [port],  "+
	"!test <user> [port] = test that user on given [port]"

IrcCommandManager.register 'test' do |m|
	user = m.from
	port = 2300

	if arg1 = m.args.shift
		if arg1 =~ /^[0-9]+$/
			port = arg1
		else
			nick = arg1
			unless user = IrcUser.find_by_nick(nick)
				m.reply "Unknown user"
				break
			end
			if arg2 = m.args.shift
				port = arg2
				unless port =~ /^[0-9]+$/
					m.reply "[port] must be a number..."
					break
				end
			end
		end
	end

	unless user.ip
		m.reply "User has hidden ip..."
		break
	end

	m.reply "testing user=#{user.nick}, ip=#{user.ip}, port=#{port}..."
	m.reply `#{ROOT}/plugins/test/test #{user.ip} #{port}`
end

