class Welcome < Irc::Plugin

  def pre_init
    @bot.command_manager.register('welcome',self)
    @db = File.expand_path("#{ROOT}/db/welcomed.yaml")
  end

  def join m
    nick = m.user.nick.downcase
    return if nick == @bot.nick.downcase
    return if welcomed.include? nick
    @bot.say nick, welcome_message
    @bot.say nick, "Type 'welcome off' to stop receiving this message."
  end

  def help m=nil, topic=nil
    "welcome off => Stop sending you welcome message when you join.  "+
    "welcome on => Start sending you welcome message when you join."
  end

  def command m
    nick = m.source.nick.downcase
    users = welcomed
    case m.params[0]
    when "",nil
      m.reply help
    when "off"
      users << nick unless users.include?(nick)
      m.reply "Welcome message turned off..."
    when "on"
      m.reply "Welcome message turned on..."
      users.delete nick
    end
    save users
  end

  def welcome_message
    file_path = "#{ROOT}/db/welcome_message.txt"
    next unless FileTest.exist? file_path
    File.read(file_path).gsub(/\n/,' ')
  end

  def save data
    file = File.open(@db,'w+')
    YAML.dump(data,file)
    file.close
  end

  def welcomed
    File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

end
