require 'socket'
class Irc::Client < EM::Connection

  include EM::Protocols::LineText2
  include Irc::HandleMessage
  include Irc::Helpers

  attr_reader :event, :name, :nick_sent, :realname, :server, :port, :username, :hostname, :config
  attr_accessor :nick, :ignored

  def initialize
    @name     = "RubyIrcClient"
    @nick     = "RubyIrcClient"
    @password = ""
    @realname = "RubyIrcClient"
    @server   = "irc.freenode.net"
    @port     = 6667
    @default_channels = ['#forsaken']
    @ignored  = []
    @event    = Event.new
    @timer    = Timer.new
    @username = Process.uid
    @servername = Socket.gethostname
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

