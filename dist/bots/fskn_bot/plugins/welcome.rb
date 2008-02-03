class Welcome < Meth::Plugin

  #
  # Startup/Shutdown
  #

  def initialize *args
    super *args
    setup_join_event
    @bot.command_manager.register('welcome',self)
    # turn off list
    @db = File.expand_path("#{BOT}/db/welcomed.yaml")
    @welcomed = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def cleanup *args
    super *args
    destroy_join_event
    @bot.command_manager.unregister('welcome',self)
  end

  #
  # Join Event
  #

  def setup_join_event
    if @bot.name == 'fskn_bot'
      @welcome_message = Proc.new{|m|
        # dont send to my self
        next if m.user.nick.downcase == @bot.nick.downcase
        # dont send to ignored users
        next if @bot.ignored.include? m.user.nick.downcase
        # dont send to poeple who opted out
        next if @welcomed.include? m.user.nick.downcase
        # send the message
        @bot.say(m.user.nick, welcome_message)
      }
      @bot.event.register("irc.message.join",@welcome_message)
    end
  end

  def destroy_join_event
    if @bot.name == 'fskn_bot'
      @bot.event.unregister("irc.message.join",@welcome_message)
    end
  end

  #
  # Commands
  #

  def help m=nil, topic=nil
    "welcome [user] => Send welcome message to user.  "+
    "welcome off => Stop sending you welcome message when you join the channel.  "+
    "welcome on => Start sending you welcome message when you join the channel."
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

  def send m
    # check user in channel
    nick = m.params.shift
    unless m.channel.users.detect{|u|u.nick.downcase == nick.downcase}
      m.reply "User does not exist in channel..."
      return
    end
    # feedback
    m.reply "Welcome message has been sent."
    # do it
    @bot.say nick, welcome_message
  end

  #
  # Helpers
  #

  private

  def welcome_message
    file_path = "#{BOT}/db/welcome_message.txt"
    next unless FileTest.exist? file_path
    File.read(file_path).gsub(/\n/,' ')
  end

  def save
    file = File.open(@db,'w+')
    YAML.dump(@welcomed,file)
    file.close
  end

end
