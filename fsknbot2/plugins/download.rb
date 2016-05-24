IrcCommandManager.register 'download', "prints url to download px." do |m|
	m.reply File.read("#{ROOT}/db/download.link.txt")
end
