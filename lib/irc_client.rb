
module IrcMethods

  # sent a message to target => user/channel
  def say target, message
    send_data "PRIVMSG #{target} : #{message}\n"
  end

  # join chat/chats
  def join channels
    channels = channels.split(' ') if channels.is_a? String
    channels.each do |channel|
     send_data "JOIN #{channel.to_s}\n"
    end
  end

  # get a list of users
  def who channels
    send_data "WHO #{channels.to_s}\n"
  end

  # send a pong reply
  def pong key
    send_data "PONG #{key}\n"
  end

  # set your nick
  def nick nick
    send_data "NICK #{nick}\n"
  end

  # send user string
  def user username, hostname, server, realname
    send_data "USER #{username} #{hostname} #{server} :#{realname}\n"
  end

end

# user model
require 'resolv'
class User
  attr_accessor :server, :channel, :username,
                :hostname, :nick, :flags, :realname
  def initialize *args
    @server   = args.shift
    @channel  = args.shift
    @username = args.shift
    @hostname = args.shift
    @nick     = args.shift
    @flags    = args.shift
    @realname = args.shift
  end
  def ip
    return @ip if @ip
    begin
      return (@ip = Resolv.getaddress hostname)
    rescue Resolv::Error
      puts "DEBUG Resolv::Error #{$!}"
    end
    nil
  end
end

=begin Pointless ? just use array ?
class Users
  def initialize
    @users = []
  end
  def add *args #server, channel, username, hostname, nick, flags, realname
    @users << (user = User.new(*args))
  end
  def length
    @users.length
  end
end
=end

# handle irc
class IrcClient < EM::Connection

  # startup
  def initialize *args
    super
    # list of users
    @users = []
  end

  # line protocol
  include EM::Protocols::LineText2

  # irc helpers
  include IrcMethods

  # defaults
  @@em_type  = :client
  @@servers  = []
  @@server   = "localhost"
  @@nick     = "irclient"
  @@channels = ""
  @@username = Process.uid
  @@hostname = "localhost"
  @@realname = "IrcClient"
  @@target   = "," # special flag for command

  # accessors
  def self.em_type; @@em_type; end 
  def self.servers; @@servers; end 

  # data being sent
  def send_data line

    # log output
    puts ">>> #{line}"

    # send output
    super line

  end

  # connection up
  def post_init
   
    # login
    user @@username, @@hostname, @@server, @@realname

    # nick
    nick @@nick

  end

  # new line recieved
  def receive_line line

    # log input
    puts "<<< #{line}"

    # handle input
    case line

    #########
    # ping
    #########

    when /^PING ([^\n]*)$/i

      # send pong
      pong $1

    #################
    # Authentication
    #################

    # pointless auth messages
    when /^:[^ ]* NOTICE AUTH/i

    # login completed
    when /^:[^ ]* 001 /i

      # join channels
      join @@channels

    ################
    # joined a room
    ################

    when /:#{@@nick}![^@]*@[^ ]* JOIN :([^\n]*)$/i

      channels = $1

      # get list of users
      who channels

    #################
    # who responses
    #################

    # single user
    when /:([^ ]*) 352 [^ ]* (#[^ ]*) ([^ ]*) ([^ ]*) [^ ]* ([^ ]*) ([^:]* :[^ ]*) ([\n]*)/i

      server   = $1 # server
      channel  = $2 # in channel
      username = $3 # uid
      hostname = $4 # hostname
      nick     = $5 # irc nick
      flags    = $6 # irc flags
      realname = $7 # MethBot

      # add user to the list
      @users << User.new(server, channel, username, hostname, nick, flags, realname)
    
    # end of who list
    when /:[^ ]* 315/i

    ###################
    # private messages
    ###################

    # privmsg detected
    when /^:[^ ]* PRIVMSG (#[^ ]*) :([^\n]*)$/i

      # delegate
      (channel,message) = [$1,$2]

      # do we have a command ?
      command = false

      # check our name name
      if message =~ /^#{@@nick}: /
        # remove our name
        message.slice!(/^#{@@nick}: /)
        command = true
      end

      # detect special target
      if message =~ /^#{@@target}/
        message.slice!(/^#{@@target}/)
        command = true
      end

      # provide words as array
      params  = message.split(' ')

      # first word is command
      command = params.shift if command
       
      # send command to user script
      privmsg(command,channel,message)

    ###############
    # not handled
    ###############
    else

      # log
      puts "--- Unhandled Input ---" # line is allready printed

    end
  end

end

