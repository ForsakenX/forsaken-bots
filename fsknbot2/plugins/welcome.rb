
IrcCommandManager.register 'welcome',
"welcome list => List messages.  "+
"welcome show <message> => Show a message.  "+
"welcome everyone => Welcome everyone in chat.  "+
"welcome <nick> => Welcome user. "

IrcCommandManager.register 'welcome' do |m|
  WelcomeCommand.command m
end

IrcHandleLine.events[:join].register do |nick|
  WelcomeCommand.welcome nick.downcase
end

class WelcomeCommand
  class << self

    @@db_dir = "#{ROOT}/db/welcomes"

    def welcome nick
      return if nick.nil? || nick.empty?
      return if nick == $nick # don't send messages to our selves
      return if IrcUser.hidden nick
      welcome_files.each do |file|
        IrcConnection.privmsg nick, read(file+".txt")
      end
    end

    def command m
	arg = m.args.shift
      case arg
      when 'list'
        m.reply "messages => "+welcome_files.sort.join(', ')
      when 'show'
        file = m.args.shift
        return m.reply("Unknown message") unless welcome_files.include? file
        msg = read("#{file}.txt")
        who = m.args.shift
        return m.reply("#{m.args.first} => " + msg) unless who
        IrcConnection.privmsg( who, msg )
        m.reply "Message sent."
      when 'everyone'
        return m.reply("You are not authorized") unless m.from.authorized?
        IrcUser.users.each do |user|
          welcome user.nick
        end
      else
        return m.reply("You are not authorized") unless m.from.authorized?
	welcome arg
      end
    end

    def save file, db
      file = File.open(file,'w+')
      YAML.dump(db,file)
      file.close
    end

    def read file
      File.read("#{@@db_dir}/#{file}").gsub("\n",' ')
    end

    def welcome_files
      list.map{|w|File.basename(w.sub(/.txt$/,''))}.sort
    end

    def list
      Dir[ @@db_dir + "/*.txt" ]
    end

  end
end

