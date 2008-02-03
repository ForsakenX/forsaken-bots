class Meth::Bot < Irc::Client

  attr_reader   :plugin_manager, :command_manager, :logger
  attr_accessor :target

  def plugins; @plugin_manager.plugins; end

  def initialize
    super(CONFIG['name'],     CONFIG['nick'], CONFIG['password'],
          CONFIG['realname'], CONFIG['server'], CONFIG['port'],
          CONFIG['channels'])
    @logger       = Logger.new("#{BOT}/logs/#{@name}",CONFIG['logger']['rotate'])
    @logger.level = Logger.const_get(CONFIG['logger']['severity'])
    @target       = CONFIG['target']||nil
    @command_manager = Meth::CommandManager.new(self)
    @plugin_manager  = Meth::PluginManager.new(self)
    @event.register('irc.message.privmsg',Proc.new{|m| privmsg m })
  end

  #
  #  Loggers
  #
 
  def privmsg m
    channel = m.channel ? m.channel.name : ""
    @logger.info ">>> "+
         "#{@name} "+
         "#{channel} " +
         "(#{Time.now.strftime('%I:%M:%S %p')}) "+
         "#{m.source.nick}: #{m.message}"
  end

  def post_init *args
    @event.call('irc.post_init',nil)
    @logger.info "Connected #{@name} to #{@server}:#{@port}"
    super *args
  end

  def say to, message
    @logger.info ":#{@name} #{to} (#{Time.now.strftime('%I:%M:%S %p')}) #{@nick}: #{message}"
    super(to,message)
  end
  
  def receive_line line
    @logger.info "[INPUT] #{line}"
    super line
  end

  def send_data line
    @logger.info "[OUTPUT] #{line}"
    super line
  end

end

