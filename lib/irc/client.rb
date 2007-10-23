require 'socket'
class Irc::Client < EM::Connection

  #
  # Class
  #

  @@clients = {}

  # reader
  def self.clients; @@clients; end

  #
  # Instance
  #

  # startup
  def initialize(config)
    #
    @event = Irc::Event.new(@logger)
    # 
    @config = config
    @name   = @config['name']
    # exits?
    if @@clients[@name]
      throw "Client by that name allready exists"
    end
    @@clients[@name] = self
    #
    @server = {
      :host => config["host"],
      :port => config["port"]||6667
    }
    #
    @nick     = config['nick']
    @realname = config['realname']
    # automatics
    @username = Process.uid
    @hostname = Socket.gethostname
    #
    #
    EM::connect(@server[:host], @server[:port], self)
  end

  #
  # Readers
  #
  
  attr_reader :event, :name, :nick_sent, :realname, :server, :username, :hostname, :config
  attr_accessor :nick

  def servers
    servers = []
    @clients.each do |client|
      servers << client.server
    end
    servers
  end

  def channels
    channels = {}
    Irc::Channel.channels.each do |name,channel|
      next if channel.server.nil?
      channels[name] = channel if channel.server[:host] == @server[:host] &&
                                  channel.server[:port] == @server[:port]
    end
    channels
  end

  def users
    users = []
    Irc::User.users.each do |user|
      users << user if user.server[:host] == @server[:host] &&
                       user.server[:port] == @server[:port]
    end
    users
  end

  #
  # Irc Actions
  #

  # send a message to user or channel
  def say to, message
    return message unless message
    message = message.to_s
    # for each line
    message.split("\n").each do |message|
      # send at chunks of 350 characters
      # scan up to extra 50 non space characters
      # biggest word in english language is 45 characters
      # this stops worsd from getting cut up
      message.scan(/.{1,300}[^ ]{0,50}/m){|chunk|
        send_data "PRIVMSG #{to} :#{chunk}\n"
      }
    end
    message
  end

  # join chat/chats
  def join channels
    return if channels.nil?
    channels = channels.split(' ') if channels.is_a? String
    channels.each do |channel|
     send_data "JOIN #{channel.to_s}\n"
    end
  end

  # set your nick
  def send_nick nick=nil
    unless nick.nil?
      @nick_sent = nick
      send_data "NICK #{nick}\n"
    end
  end

  #
  # EventMachine::Connection
  #
 
  # line protocol
  include EM::Protocols::LineText2

  # fake new method for EM
  def new sig
    @signature = sig
    post_init
    self
  end

  # connection started
  def post_init
    # send password
    send_data "PASS #{@config['password']}\n" if @config['password']
    # login
    send_data "USER #{@username} #{@hostname} #{@server[:host]} :#{@realname}\n"
    # send initial nick
    send_nick @nick
  end

  # new line recieved
  def receive_line line
    # handle message
    Irc::HandleMessage.new(self,line)
  end

end

