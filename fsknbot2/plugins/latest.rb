IrcCommandManager.register 'latest', "prints url to latest version" do |m|
        version = File.read("./db/latest.txt")
	m.reply "#{version} => http://fly.thruhere.net/versions/#{version}" 
end
