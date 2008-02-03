require 'socket'
class Irc::Client < EM::Connection

  include EM::Protocols::LineText2
  include Irc::HandleMessage
  include Irc::Helpers

  attr_reader :event, :name, :nick_sent, :realname, :server, :username, :hostname, :config
  attr_accessor :nick, :ignored

  def initialize(name,nick,realname,host,port,default_channels)
    @name     = name     ||"RubyIrcClient"
    @nick     = nick     ||"RubyIrcClient"
    @realname = realname ||"RubyIrcClient"
    @server   = { :host => (host||"irc.freenode.net"),
                  :port => (port||6667) }
    @default_channels = default_channels
    @ignored  = []
    @logger   = Logger.new(STDOUT)
    @event    = Irc::Event.new(@logger)
    @timer    = Irc::Timer.new
    @username = Process.uid
    @hostname = Socket.gethostname
  end

  def post_init
    # send password
    send_data "PASS #{@config['password']}\n" if @config['password']
    # login
    send_data "USER #{@username} #{@hostname} #{@server[:host]} :#{@realname}\n"
    # send initial nick
    send_nick @nick
  end

  def unbind
    reconnect @server[:host], @server[:port]
    post_init
  end

  def receive_line line
    handle_message line
  end

end

