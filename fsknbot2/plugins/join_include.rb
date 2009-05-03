
next if IrcUser.hidden nick 

if nick =~ /^ski/
	IrcConnection.privmsg "#forsaken",
		"Maybe if you stuck around we'd have a game..."
	IrcUser.users.each do |user|
		next unless user.nick =~ /^ski/
		next if user.nick == nick
		IrcConnection.kick user.nick, "your welcome"
	end
end

IrcConnection.privmsg "#forsaken", GamesCommand.run

