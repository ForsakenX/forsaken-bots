class Meth::Bot < Irc::Client

  #
  # Instance
  #

  # instance reader/writers
  attr_reader   :event, :plugin_manager, :logger
  attr_accessor :target

  # easy access from @bot
  def plugins; @plugin_manager.plugins; end

  def initialize(config)
    # setup bot logger
    @logger = Logger.new("#{DIST}/logs/#{config['name']}",config['logger']['rotate'])
    @logger.level = Logger.const_get(config['logger']['severity'])
    # set defaults
    @logger.info "Connecting #{config['name']} to #{config['host']}:#{config['port']}"
    #
    @event = Meth::Event.new(@logger)
    @timer = Meth::Timer.new
    #
    @target = config['target']||nil
    # do defaults
    # and connect
    super config
    # needs settings from super
    @plugin_manager = Meth::PluginManager.new(self)
    # Custom Bot Initializations
    init="#{DIST}/conf/#{$config_file}.rb"
    if File.executable?(init)
      eval(File.read(init))
    end
    # fucked up
    @event.call('irc.post_init',nil)
  end

  #
  # Callbacks
  #

  def _listen m
    @event.call('irc.message.listen',m)
  end

  def _notice m
    puts m.line
    @event.call('irc.message.notice',m)
  end

  def _join m
    puts m.line
    @event.call('irc.message.join',m)
  end

  def _part m
    puts m.line
    @event.call('irc.message.part',m)
  end

  def _quit m
    puts m.line
    @event.call('irc.message.quit',m)
  end

  def _unknown m
    @logger.warn "Unknown Message <<< #{m.line}"
    @event.call('irc.message.unknown',m)
  end

  def _privmsg m

    puts ">>> "+
         "#{@name} #{m.channel} " +
         "(#{Time.now.strftime('%I:%M:%S %p')}) "+
         "#{m.source.nick}: #{m.message}"

    # parse and create command/params properties
    parse_command m

    # call easy to use command event
    if m.command
      @logger.info "Command called: #{m.command.downcase}"
      @event.call("command.#{m.command.downcase}",m)
    end

    # call privmsg event
    @event.call('irc.message.privmsg',m)

  end

  #
  # Methods
  #
  
  def parse_command m

    # m.message with a command is one of the following
    # ",hi 1 2 3"
    # "MethBot: hi 1 2 3"

    # must become...
    # m.command => hi
    # m.message => 1 2 3

    # look for our nick or target as first word
    # then extract them from the message
    # "(<nick>: |<target>)"
    unless is_command = !m.message.slice!(/^#{Regexp.escape(@nick)}: /).nil?
      # addressed to target
      unless @target.nil?
        is_command = !m.message.slice!(/^#{Regexp.escape(@target)}/).nil?
      end
    end

    # "hi 1 2 3"
    # now that nick/target is extracted
    # thats how the message looks
    # includes the command and params

    # if its a pm then its allways a command
    is_command = m.personal if !is_command

    # %w{hi 1 2 3}
    # split words in line
    params = m.line.split(' ')
    m.instance_variable_set(:@params,params)
    class <<m; attr_accessor :params; end

    # "hi"
    # the command
    command = m.params.shift
    m.instance_variable_set(:@command,command)
    class <<m; attr_accessor :command; end

    # m.message is now the command params
    # m.command is now the command
    # m.params is now an array of words after the command

  end

  #
  #  Console
  #  Loggers
  #

  def post_init *args
    super *args
    @logger.info "Connected #{@name} to #{@server[:host]}:#{@server[:port]}"
  end

  def say to, message
    puts "<<< "+
         "#{@name} #{to} " +
         "(#{Time.now.strftime('%I:%M:%S %p')}) "+
         "#{@nick}: #{message}"
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

