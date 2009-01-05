IrcHandleLine.events[:join].register do |nick|
	%w{ski* meth* *term*}.each do |mask|
		next unless nick =~ /#{mask}/
		IrcConnection.privmsg nick,
			"Please click here:  "+
			"http://fly.thruhere.net/chat/?"+nick
		break
	end
end
