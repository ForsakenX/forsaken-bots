class Welcome < Meth::Plugin

  #
  # Startup/Shutdown
  #

  def initialize *args
    super *args
    setup_join_event
    @bot.command_manager.register('welcome',self)
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
        next if @client.ignored.include? @source.nick.downcase
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
    "welcome [user] => Send welcome message to user."
  end

  def command m
    # check params
    unless nick = m.params.shift
      m.reply help
      return
    end
    # check user in channel
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
    file_path = "#{DIST}/bots/#{$bot}/db/welcome_message.txt"
    next unless FileTest.exist? file_path
    File.read(file_path).gsub(/\n/,' ')
  end

end
