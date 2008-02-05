class Meth::Bot < Irc::Client

  attr_reader   :plugin_manager, :command_manager
  attr_accessor :target

  def initialize
    # client stuff
    super
    @name     = CONFIG['name']
    @nick     = CONFIG['nick']
    @password = CONFIG['password']
    @realname = CONFIG['realname']
    @server   = CONFIG['server']
    @port     = CONFIG['port']
    @default_channels = CONFIG['channels']
    # change @logger
    @@logger.close
    @@logger = Logger.new("#{BOT}/logs/#{CONFIG['name']}")
    @@logger.level = Logger.const_get(CONFIG['logger']['severity'])
    # bot stuff
    @target = CONFIG['target']||nil
    @command_manager = Meth::CommandManager.new(self)
    @plugin_manager  = Meth::PluginManager.new(self)
    @event.register('irc.message.privmsg',Proc.new{|m| privmsg m })
  end

  #
  #  Helpers
  #

  def plugins
    @plugin_manager.plugins
  end

  #
  #  Loggers
  #
 
  def privmsg m
    channel = m.channel ? m.channel.name : ""
    @@logger.info ">>> "+
         "#{@name} "+
         "#{channel} " +
         "(#{Time.now.strftime('%I:%M:%S %p')}) "+
         "#{m.source.nick}: #{m.message}"
  end

  def say to, message
    @@logger.info ":#{@name} #{to} (#{Time.now.strftime('%I:%M:%S %p')}) #{@nick}: #{message}"
    super(to,message)
  end
  
  def post_init *args
    @event.call('irc.post_init',nil)
    @@logger.info "Connected #{@name} to #{@server}:#{@port}"
    super *args
  end

  def receive_line line
    @@logger.info "<<< #{line}"
    super line
  end

  def send_data line
    @@logger.info ">>> #{line}"
    super line
  end

end

