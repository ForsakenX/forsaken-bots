require 'socket'
class Irc::Client < EM::Connection

  include EM::Protocols::LineText2
  include Irc::HandleMessage
  include Irc::Helpers

  @@logger = Logger.new(STDOUT)
  def self.logger; @@logger; end
  def self.logger=(logger); @@logger=logger; end
  def logger; @@logger; end
  def logger=(logger); @@logger=logger; end

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
    @event    = Irc::Event.new
    @timer    = Irc::Timer.new
    @username = Process.uid
    @servername = Socket.gethostname
  end

  def post_init
    @event.call('irc.post_init',nil)
    @@logger.info "Connected #{@name} to #{@server}:#{@port}"
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
    @@logger.info "<<< #{line}"
    # profiling
    handle_message line
    seconds = Time.now-time
    if seconds > 60
      minutes = seconds / 60
      seconds = seconds % 60
    end
    @@logger.info "Time Taken => #{minutes}:#{seconds}"
  end

  def send_data line
    @@logger.info ">>> #{line}"
    @event.call('irc.send_data',line)
    super line
  end

end

