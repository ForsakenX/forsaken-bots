
#IrcCommandManager.register 'welcome',
#"welcome <nick> => Welcome user. "

#IrcCommandManager.register 'welcome' do |m|
#  WelcomeCommand.command m
#end

IrcHandleLine.events[:join].register do |channel,nick|
  WelcomeCommand.welcome nick.downcase if channel == "#forsaken"
end

class WelcomeCommand
  class << self

    @@db_dir = "#{ROOT}/db/welcomes"

    def welcome nick
      return if nick.nil? || nick.empty?
      return if nick == $nick # don't send messages to our selves
      return if IrcUser.hidden nick
			puts "#{nick} last seen: #{Seen.last?(nick).to_s} (nil=#{Seen.last?(nick).to_s.nil?})"
			if Seen.last?(nick).nil?
				Seen.set(nick,Time.now)
				IrcConnection.privmsg '#forsaken', 
					read(@@db_dir + "/never_seen").gsub(/<nick>/,nick)
			end
      list.each do |file|
				begin
					data = read(file)
        	IrcConnection.privmsg nick,
						(file =~ /\.rb$/ ? eval(data) : data),
						"NOTICE"
				rescue Exception
          puts "Error executing #{file}, #{$!}"
				end
      end
    end

    def command m
      file = m.args.shift
      return m.reply("You are not authorized") unless m.from.authorized?
      welcome file
    end

    def read file
      File.read(file).gsub("\n",' ')
    end

    def list
      Dir[ @@db_dir + "/*.txt", @@db_dir + "/*.rb" ].sort
    end

  end
end
