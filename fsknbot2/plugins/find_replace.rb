IrcChatMsg.register do |m|
	FindReplace.watch m
end
class FindReplace
	@@log = {}
	def self.bold str
		# doesn't seem to work right
		#"\002" + str + "\017"
		str
	end
	def self.watch m
		nick = m.from.nick
		key = nick.downcase.to_sym
		unless m.message =~ %r{^\s*#{$prefix}s(.)([^/\1]*)(\1(([^/\1]*)(\1([a-z]*))?)?)?}
			@@log[key] = m.message
			return
		end
		find, replace, switches = $2.to_s, $5.to_s, $7.to_s
		return unless last_line = @@log[key]
		if switches =~ /g/
			fixed = last_line.gsub(/#{find}/,bold(replace))
		else
			fixed = last_line.sub(/#{find}/,bold(replace))
		end
		m.reply "<#{nick}> #{fixed}"
	rescue
		m.reply "Error: #{$1}"
	end
end
