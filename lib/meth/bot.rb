class Meth::Bot < Irc::Client

  #
  # Instance
  #

  # instance reader/writers
  attr_reader :name, :server, :nick, :channels
  attr_accessor :realname, :target

  # easy access from @bot
  def plugins; Meth::PluginManager.plugins; end
  def bots;    Meth::BotManager.bots;       end
  def timer;   Meth::Timer;                 end
  def event;   Meth::Event;                 end

  def initialize(config)
    # defaults
    super
    # copy in configs
    @name     = config['name']     || "freenode"
    @target   = config['target']   || ","
    @server   = config['server']   || "irc.freenode.org"
    @nick     = config['nick']     || "MethBot_#{username}_#{hostname}"
    @channels = config['channels'] || ["#methbot"]
    @realname = config['realname'] || "MethBot beta"
    # load plugins
    Meth::PluginManager.startup self
  end

  #
  # Callbacks
  #

  def _listen m
    #Meth::PluginManager.do_all('listen',m)
    event.call('irc.message.listen',m)
  end

  def _privmsg m
    puts ">>> "+
         "#{@name} #{m.channel} " +
         "(#{Time.now.strftime('%I:%M:%S %p')}) "+
         "#{m.source.nick}: #{m.message}"
    event.call('irc.message.privmsg',m)
    # parses and call command event
    do_command(m)
  end

  def _notice m
    puts m.line
    event.call('irc.message.notice',m)
  end

  def _join m
    puts m.line
    event.call('irc.message.join',m)
  end

  def _part m
    puts m.line
    event.call('irc.message.part',m)
  end

  def _quit m
    puts m.line
    event.call('irc.message.quit',m)
  end

  def _unknown m
    $logger.warn "Unknown Message <<< #{m.line}"
    event.call('irc.message.unknown',m)
  end

  #
  #  Console
  #  Loggers
  #

  def post_init *args
    super *args
    puts "Connected #{@name} to #{@server}:#{@port}"
  end

  def say to, message
    puts "<<< "+
         "#{@name} #{to} " +
         "(#{Time.now.strftime('%I:%M:%S %p')}) "+
         "#{@nick}: #{message}"
    super(to,message)
  end
  
  def receive_line line
    $logger.info "<<< #{line}"
    super line
  end

  def send_data line
    $logger.info ">>> #{line}"
    super line
  end

  #
  # Bot Methods
  #

  def do_command m

    # m.message with a command is one of the following
    # ",hi 1 2 3"
    # "MethBot: hi 1 2 3"

    # must become...
    # m.command => hi
    # m.message => 1 2 3

    # look for our nick or target as first word
    # then extract them from the message

    # "(<nick>: |<target>)"
    unless is_command = !m.message.slice!(/^#{@nick}: /).nil?
      # addressed to target
      unless @target.nil?
        is_command = !m.message.slice!(/^#{@target}/).nil?
      end
    end

    # "hi 1 2 3"
    # now that nick/target is extracted
    # the rest is the message
    # that includes the command and params

    # if its a pm then its allways a command
    is_command = m.personal if !is_command

    # at this point if its not a command
    # where done working with this message
    return unless is_command

    # %w{hi 1 2 3}
    # split words in line
    m.instance_variable_set(:@params,m.line.split(' '))
    class <<m; attr_accessor :params; end

    # "hi"
    # the command
    m.instance_variable_set(:@command,m.params.shift)
    class <<m; attr_accessor :command; end

    # call command event
    event.call("command.#{m.command}",m)

  end
end


