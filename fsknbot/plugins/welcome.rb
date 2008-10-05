class Welcome < Irc::Plugin

  def pre_init
    @bot.command_manager.register('welcome',self)
    @db = File.expand_path("#{ROOT}/db/welcomed.yaml")
    @welcomed = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def join m
    nick = m.user.nick.downcase
    next if nick == @bot.nick.downcase
    next if @welcomed.include? nick
    @bot.say nick, welcome_message
    @bot.say nick, "Type 'welcome off' to stop receiving this message."
  end

  def help m=nil, topic=nil
    "welcome off => Stop sending you welcome message when you join.  "+
    "welcome on => Start sending you welcome message when you join."
  end

  def command m
    nick = m.source.nick.downcase
    case m.params[0]
    when "",nil
      m.reply help
    when "off"
      @welcomed << nick unless @welcomed.include?(nick)
      m.reply "Welcome message turned off..."
      save
    when "on"
      @welcomed.delete nick
      m.reply "Welcome message turned on..."
      save
    end
  end

  def welcome_message
    file_path = "#{ROOT}/db/welcome_message.txt"
    next unless FileTest.exist? file_path
    File.read(file_path).gsub(/\n/,' ')
  end

  def save
    file = File.open(@db,'w+')
    YAML.dump(@welcomed,file)
    file.close
  end

end
