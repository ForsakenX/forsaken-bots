require 'socket'
class Irc::Client < EM::Connection

  include EM::Protocols::LineText2
  include Irc::HandleMessage
  include Irc::Helpers

  attr_reader :event, :name, :nick_sent, :realname, :server, :port, :username, :hostname, :config
  attr_accessor :nick, :ignored

  def initialize(name,nick,realname,password,server,port,default_channels)
    @name     = name     ||"RubyIrcClient"
    @nick     = nick     ||"RubyIrcClient"
    @password = password || ""
    @realname = realname ||"RubyIrcClient"
    @server   = server   ||"irc.freenode.net"
    @port     = port     ||6667
    @default_channels = default_channels
    @ignored  = []
    @logger   = Logger.new(STDOUT)
    @event    = Irc::Event.new(@logger)
    @timer    = Irc::Timer.new
    @username = Process.uid
    @servername = Socket.gethostname
  end

  def post_init
    # send password
    send_data "PASS #{@password}\n" if @password
    # login
    send_data "USER #{@username} #{@servername} #{@server} :#{@realname}\n"
    # send initial nick
    send_nick @nick
  end

  def unbind
    reconnect @server, @port
    post_init
  end

  def receive_line line
    handle_message line
  end

end

