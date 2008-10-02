require 'socket'
class Irc::Client < EM::Connection

  include EM::Protocols::LineText2
  include Irc::HandleMessage
  include Irc::Helpers

  def plugins; @plugin_manager.plugins; end
  def commands; @command_manager.commands; end

  attr_reader :event, :name, :nick_sent, :realname, :server,
              :port, :username, :hostname, :config, :plugin_manager, 
	      :command_manager
  attr_accessor :nick, :ignored, :target

  def initialize
    @name     = CONFIG['name']
    @nick     = CONFIG['nick']
    @password = CONFIG['password']
    @realname = CONFIG['realname']
    @server   = CONFIG['server']
    @port     = CONFIG['port']
    @default_channels = CONFIG['channels']
    @target   = CONFIG['target']||nil
    @ignored  = []
    @event    = Event.new
    @timer    = Timer.new
    @username = Process.uid
    @servername = Socket.gethostname
    @command_manager = Irc::CommandManager.new(self)
    @plugin_manager  = Irc::PluginManager.new(self)
  end

  def post_init
    @event.call('irc.post_init',nil)
    LOGGER.info "Connected #{@name} to #{@server}:#{@port}"
    # send password
    send_data "PASS #{@password}\n" if @password
    # login
    send_data "USER #{@username} #{@servername} #{@server} :#{@realname}\n"
    # send initial nick
    send_nick @nick
  end

  def unbind
    @event.call('irc.unbind',nil)
    reconnect @server, @port
    post_init
  end

  def receive_line line
    time = Time.now
    @event.call('irc.receive_line',line)
    LOGGER.info "<<< #{line}"
    handle_message line, time
    LOGGER.info "Time Taken (seconds) => #{Time.now-time}"
  end

  def send_data line
    LOGGER.info ">>> #{line}"
    @event.call('irc.send_data',line)
    super line
  end

end

