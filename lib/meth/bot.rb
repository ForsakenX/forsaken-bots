class Meth::Bot < Irc::Client

  #
  # Instance
  #

  # instance reader/writers
  attr_reader   :plugin_manager, :command_manager, :logger
  attr_accessor :target

  # easy access from @bot
  def plugins; @plugin_manager.plugins; end

  def initialize(config)
    # setup bot logger
    @logger = Logger.new("#{DIST}/bots/#{$bot}/logs/#{config['name']}",config['logger']['rotate'])
    @logger.level = Logger.const_get(config['logger']['severity'])
    # set defaults
    @logger.info "Connecting #{config['name']} to #{config['host']}:#{config['port']}"
    #
    @target = config['target']||nil
    # do defaults
    # and connect
    super config
    # command manager
    @command_manager = Meth::CommandManager.new(self)
    # needs settings from super
    @plugin_manager = Meth::PluginManager.new(self)
    # Custom Bot Initializations
    init="#{DIST}/bots/#{$bot}/conf/init.rb"
    if File.executable?(init)
      eval(File.read(init))
    end
    # fucked up
    @event.call('irc.post_init',nil)
    # events
    @event.register('irc.message.privmsg',Proc.new{|m| privmsg m })
  end

  #
  #  Console
  #  Loggers
  #
 
  def privmsg m
    channel = m.channel ? m.channel.name : ""
    puts ">>> "+
         "#{@name} "+
         "#{channel} " +
         "(#{Time.now.strftime('%I:%M:%S %p')}) "+
         "#{m.source.nick}: #{m.message}"
  end

  def post_init *args
    super *args
    @logger.info "Connected #{@name} to #{@server[:host]}:#{@server[:port]}"
  end

  def say to, message
    puts ":#{@name} #{to} (#{Time.now.strftime('%I:%M:%S %p')}) #{@nick}: #{message}"
    super(to,message)
  end
  
  def receive_line line
    @logger.info "<<< #{line}"
    super line
  end

  def send_data line
    @logger.info ">>> #{line}"
    super line
  end

end

