IrcHandleLine.events[:join].register do |nick|
	eval(File.read("#{ROOT}/plugins/join_include.rb"))
end
