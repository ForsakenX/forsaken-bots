class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2
  def initialize *args
    super *args
    @bot     = nil
    @channel = nil
    reply help
  end
  def receive_line line
    params = line.chomp.split(' ')
    return unless params.length > 0
    case params.shift
    # say <bot-name> <channel> <msg>
    when "say"
      say params
    when "set"
      set params
    when "!"
      _! params
    # help
    else #when "help"
      reply "Not a recognized command. "+
            help(params)
    end
  end
  # say <msg>
  def say params
    channel = nil
    if @bot.nil?
      reply "ERROR - Bot is not selected"
      return
    end
    if @channel.nil?
      reply "ERROR - Channel is not selected"
      return
    end
    unless @bot.channels.include?(@channel)
      reply "ERROR - Not in channel: '#{@bot.name}#{@channel}'"
      reply @bot.channels
      return
    end
    message = params.join(' ').chomp
    # send message
    @bot.say(@channel,message)
  end
  # set <server-name> [<channel>]
  def set params
    unless bot = params.shift
      reply "ERROR - Missing <bot-name> argument. "+
            help('set')
      return
    end
    unless @bot = Irc::Client.clients[bot]
      reply "ERROR - Bot '#{bot}' does not exist. "
      return
    end
    unless channel = params.shift
      reply "ERROR - Missing <channel> argument. "+
            help('set')
      return
    end
    unless @bot.channels[channel]
      reply "ERROR - Not in channel: '#{@bot.name}#{channel}'"
      return 
    end
    @channel = channel
    reply "Channel set to '#{@bot.name}#{@channel}'" 
  end
  def _! params=nil
    code = params.join(' ')
    begin
      eval(code)
    rescue Exception
      reply "ERROR - #{$!}\n#{$@.join('\n')}"
    end
  end
  # help
  def help params=[]
    topic = params.shift
    case topic
    when "say"
      "say <msg>"
    when "set"
      "set <bot-name> <channel>"
    when "!"
      "! <code>"
    else
      "Commands: say"
    end
  end
  # reply
  def reply msg
    puts "*** #{msg}"
  end
end
