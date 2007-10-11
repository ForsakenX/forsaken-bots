
module Irc
   
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
  
  # put this into AR
  class Users
    @users = []
    def self.create(server, channel, username, hostname, nick, flags, realname)
      unless user = find_by_nick(nick)
        user = User.new(server, channel, username, hostname, nick, flags, realname)
        @users << user
      end
      user
    end
    def self.length
      @users.length
    end
    def self.find nick
      return find_all if nick == :all
      return find_by_nick(nick)
    end
    def self.find_all
      @users
    end
    def self.find_by_nick nick
      @users.each do |user|
        return user if user.nick.downcase == nick.downcase
      end
      nil
    end
  end

  class PrivMessage

    attr_accessor :client, :replyto, :channel, :source,
                  :message, :command, :params, :to, :personal

    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG MethBot :,hi 1 2 3
    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG #tester :MethBot: hi 1 2 3
    def initialize(client, message)

      # client object
      @client = client

      # :
      # garbage
      message.slice!(/^:/)

      # methods!1000@c-68-36-237-152.hsd1.nj.comcast.net 
      # source
      @source = nil
      source = message.slice!(/[^ ]*/)
      if source =~ /([^!]*)!([^@]*)@([^\n]*)/
        username = $2
        hostname = $3
        nick     = $1
        # do we know this user allready?
        unless @source = @client.users.find_by_nick(nick) # has more information
          # create a mock user
          @source = User.new("","",username,hostname,nick,"","")
        end
      end

      # " PRIVMSG "
      # garbage
      message.slice!(/ PRIVMSG /)

      # "(MethBot|#tester)"
      # where this message came from
      @to = message.slice!(/^([^ ]*)/)

      # channel message ?
      @channel = (@to =~ /#/) ? @to : nil

      # personal message ?
      @personal = @channel ? false : true

      # replyto
      @replyto = nil
      if @channel
        @replyto = @channel
      else
        @replyto = @source.nil? ? nil : @source.nick
      end

      # " :"
      # garbage
      message.slice!(/ :/)

      # "(MethBot: |,)"
      # addressed to us or using special target
      command = !message.slice!(/^#{@client.nick}: /).nil? || # addressed to MethBot
                !message.slice!(/^#{@client.target}/).nil?    # addressed to ,

      # if personal message than this is always a command
      command = @personal if !command

      # "hi 1 2 3"
      # the rest is the message
      @message = message

      # extract command/params
      @command = nil
      @params  = []
      if command
        # break message
        params = message.split(' ')
        # "hi"
        # the command
        @command = params.shift
        # ["1","2","3"]
        # command params
        @params  = params
      end

    end

    def reply message
      @client.say @replyto, message
    end

  end
  
  # handle irc
  require 'socket'
  class Client < EM::Connection

    # line protocol
    include EM::Protocols::LineText2

    # defaults
    @@server  = "localhost" # ircd server
    @@port    = 6667

    # accessors
    def self.server; @@server; end 
    def self.port;   @@port;   end 
  
    # accessors
    attr_accessor :remote, :nick, :channels, :username,
                  :hostname, :realname, :target, :users

    # data being sent
    def send_data line

      # log output
#      puts ">>> #{line}"

      # send output
      super line

    end

    # startup
    def initialize *args
      # defaults
      @remote   = { :ip => "remote", :port => "6667" }
      @nick     = "irclient"
      @channels = ""
      @username = Process.uid
      @hostname = "localhost"
      @realname = "Irc::Client"
      @target   = "," # special flag for command
      @users    = Users
      # user defined
      overide_defaults
      # run last
      super *args # calls post_init
    end
  
    # user defined
    def overide_defaults
    end
  
    # connection up
    def post_init
  
      # remote
      unless (peername = get_peername).nil?
        @remote[:port], @remote[:ip] = Socket.unpack_sockaddr_in(peername)
      end
     
      # login
      send_data "USER #{@username} #{@hostname} #{@@server} :#{@realname}\n"
  
      # send initial nick
      send_nick @nick

    end
 
    # sent a message to target => user/channel
    def say target, message
      # send at chunks of 350 characters
      message.scan(/.{1,350}/m){|chunk|
        send_data "PRIVMSG #{target} :#{chunk}\n"
      }
    end
  
    # join chat/chats
    def join channels
      channels = channels.split(' ') if channels.is_a? String
      channels.each do |channel|
       send_data "JOIN #{channel.to_s}\n"
      end
    end
  
    # set your nick
    def send_nick nick=nil
      unless nick.nil?
        send_data "NICK #{nick}\n"
        @nick = nick
      end
      @nick
    end

    # new line recieved
    def receive_line line

      # log input
#      puts "<<< #{line}"

      # handle input
      case line

      #########
      # ping
      #########

      when /^PING ([^\n]*)$/i

        # send pong
        send_data "PONG #{$1}\n"

      #################
      # Authentication
      #################

      # pointless auth messages
      #when /^:[^ ]* NOTICE AUTH/i

      # login completed
      when /^:[^ ]* 001 /i

        # join default channels
        join @channels

      # set nick failed
      when /^:[^ ]* 433 /i

      # MOTD
      # start, line, end
      when /^:[^ ]* (375|372|376)/

      ################
      # joining
      ################

      # joined
      when /:#{@nick}![^@]*@[^ ]* JOIN :([^\n]*)$/i

        channels = $1

        # get list of users
        send_data "WHO #{channels}\n"

      # topic
      when /^[^ ]* 332/

      # names list
      # we use /who instead
      when /^[^ ]* (353|366)/

      # who responses
      # a single user in who list
      when /:([^ ]*) 352 [^ ]* (#[^ ]*) ([^ ]*) ([^ ]*) [^ ]* ([^ ]*) ([^:]* :[^ ]*) ([\n]*)/i

        server   = $1 # server
        channel  = $2 # in channel
        username = $3 # uid
        hostname = $4 # hostname
        nick     = $5 # irc nick
        flags    = $6 # irc flags
        realname = $7 # MethBot

        # add user to the list
        Users.create(server, channel, username, hostname, nick, flags, realname)
    
      # end of who list
      when /:[^ ]* 315/i

      ###################
      # private messages
      ###################

      # privmsg detected
      when /^:[^ ]* PRIVMSG/i

        # PrivMessage Object
        message = PrivMessage.new(self,line)
      
        # send to user script
        privmsg(message)

      ###################
      # notice messages
      ###################

      # privmsg detected
      when /^:[^ ]* NOTICE/i

        # PrivMessage Object
        #message = NoticeMessage.new(self,line)
      
        # send to user script
        #notice(message)

      ###############
      # not handled
      ###############
      else

puts "<<< #{line}"

        # log
#        puts "--- Unhandled Input ---" # line is allready printed

      end
    end

  end

end
