module Irc
   
  class HandleMessage

    def initialize(client,line)

      # handle input
      case line

      #########
      # ERROR
      #########
      
      when /^ERROR/i

        exit

      #########
      # ping
      #########

      when /^PING ([^\n]*)$/i

        # send pong
        client.send_data "PONG #{$1}\n"

      #################
      # Authentication
      #################

      # pointless auth messages
      #when /^:[^ ]* NOTICE AUTH/i

      # login completed
      when /^:[^ ]* 001 /i

        # join default channels
        client.join client.channels

      # set nick failed
      when /^:[^ ]* 433 /i

        client.send_nick "#{client.nick_sent}_"

      # MOTD
      # start, line, end
      when /^:[^ ]* (375|372|376)/

      ###################
      # Channel Related #
      ###################

      # channel topic
      when /^[^ ]* 332/

      # names list
      # we use /who instead
      when /^[^ ]* (353|366)/

      # who responses
      # a single user in who list
      when /:([^ ]*) 352 [^ ]* (#[^ ]*) ([^ ]*) ([^ ]*) [^ ]* ([^ ]*) ([^:]* :[^ ]*) ([\n]*)/i

        server   = $1 # server
        channel  = $2 # in channel
        user     = $3 # uid
        host     = $4 # hostname
        nick     = $5 # irc nick
        flags    = $6 # irc flags
        realname = $7 # MethBot

        # add or update user
        if u = User.find(nick)
          u.update({:server => server, :channel => channel,
                    :user   => user,   :host    => host,
                    :nick   => nick,   :flags   => flags,
                    :realname => realname})
        else
          u = User.create({:server => server, :channel => channel,
                           :user   => user,   :host    => host,
                           :nick   => nick,   :flags   => flags,
                           :realname => realname})
        end

      # end of who list
      when /:[^ ]* 315/

      # someone joins a chat
      when /:[^ ]* JOIN/

        m = JoinMessage.new(client,line)

      # someone left a chat
      #:methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #kahn
      when /:[^ ]* PART/i

        m = PartMessage.new(client,line)

      ########
      # PART
      ########

      when /:[^ ]* QUIT/i

        m = QuitMessage.new(client,line)

      ###################
      # private messages
      ###################

      when /^:[^ ]* PRIVMSG/i

        # PrivMessage Object
        m = PrivMessage.new(client,line)
      
      ###################
      # notice messages
      ###################

      when /^:[^ ]* NOTICE/i

        # PrivMessage Object
        m = NoticeMessage.new(client,line)
      
      ###############
      # Unknown Message
      ###############
      else

        # UnkownMessage's
        m = UnknownMessage.new(client,line)

      end
    end
  end

  # handles a message
  class Message
    attr_accessor :client, :line
    def initialize(client,line)
      @client = client
      @line   = line
      @client._listen(self)
    end
  end

  # handles unknown messages
  class UnknownMessage < Message
    def initialize(client, line)
      super(client, line)
      @client._unknown(self)
    end
  end

  # handles a notice message
  class NoticeMessage < Message
    def initialize(client, line)
      super(client, line)
      @client._notice(self)
    end
  end

  # handles a join message
  class JoinMessage < Message

    attr_accessor :user

    def initialize(client, line)
      super(client, line)

      # joined
      # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net JOIN :#kahn
      unless line =~ /:([^ ]*)!([^@]*)@([^ ]*) JOIN :(#[^\n]*)$/i
        throw "Bad JOIN message..."
      end

      nick     = $1
      user     = $2
      host     = $3
      channel  = $4

      # We have joined a chat
      if client.nick == nick
        # get a list of users for channel
        client.send_data "WHO #{channel}\n"
        return
      else
        # get more details on the user
        client.send_data "WHOIS #{nick}\n"
      end

      # add or update user
      if @user = User.find(nick)
        @user.update({:channel => channel, :user => user,
                      :host    => host,    :nick => nick})
      else
        @user = User.create({:channel => channel, :user => user,
                             :host    => host,    :nick => nick})
      end


      @client._join(self)
    end

  end

  # handles a part message
  class PartMessage < Message
    attr_accessor :user
    def initialize(client,line)
      super(client,line)

      # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #kahn
      # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #tester
      unless line =~ /:([^!]*)!([^@]*)@([^ ]*) PART [:]*(#[^\n]*)$/i
        puts "Error: badly formed PART message"
        return
      end

      nick     = $1
      user     = $2
      host     = $3
      channel  = $4

      # add or update user
      if @user = User.find(nick)
=begin must setup Channel class first
        @user.update({:channel => channel, :user => user,
                      :host    => host,    :nick => nick})
      else
        @user = User.create({:channel => channel, :user => user,
                             :host    => host,    :nick => nick})
      end
=end
        @user.destroy

        @client._part(self)
      end
    end
  end

  # handles a quit message
  class QuitMessage < Message
    #:methods!1000@c-68-36-237-152.hsd1.nj.comcast.net QUIT :Quit: Leaving.
    attr_accessor :user
    def initialize(client,line)

      #
      super(client,line)

      # :MethBot_!1000@c-68-36-237-152.hsd1.nj.comcast.net QUIT :Client closed connection
      unless line =~ /:([^ ]*)!([^@]*)@([^ ]*) QUIT ([:]*.*)*$/mi
        throw "Bad QUIT message..."
      end

      # nick
      nick = $1

      # add or update user
      @user.destroy if @user = User.find(nick)

      @client._quit(self)
    end
  end

  # handles a priv message
  class PrivMessage < Message

    attr_accessor :replyto, :channel, :source, :message, :to, :personal

    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG MethBot :,hi 1 2 3
    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG #tester :MethBot: hi 1 2 3
    def initialize(client, line)
      super(client, line)

      # :
      # garbage
      line.slice!(/^:/)

      # methods!1000@c-68-36-237-152.hsd1.nj.comcast.net 
      # source
      @source = nil
      source = line.slice!(/[^ ]*/)
      if source =~ /([^!]*)!([^@]*)@([^\n]*)/
        user = $2
        host = $3
        nick = $1
        # do we know this user allready?
        unless @source = User.find(nick) # has more information
          # create a mock user
          @source = User.create({:user => user, :host => host, :nick => nick })
        end
      end

      # " PRIVMSG "
      # garbage
      line.slice!(/ PRIVMSG /)

      # "(MethBot|#tester)"
      # where this line came from
      @to = line.slice!(/^([^ ]*)/)

      # channel line ?
      @channel = (@to =~ /#/) ? @to : nil

      # personal line ?
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
      line.slice!(/ :/)

      # ",hi 1 2 3"
      # "MethBot: hi 1 2 3"
      # the rest is the message
      @message = line

      # send it to the user
      client._privmsg(self)

    end

    def reply message
      @client.say @replyto, message
    end

    def reply_directly message
      @client.say @source.nick, message
    end

  end
  
  # handle irc
  require 'socket'
  class Client < EM::Connection

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
      # login
      send_data "USER #{@username} #{@hostname} #{@server} :#{@realname}\n"
      # send initial nick
      send_nick @nick
    end

    # new line recieved
    def receive_line line
      # handle message
      HandleMessage.new(self,line)
    end

    #
    # Client Object
    #

    # accessors
    attr_accessor :nick, :nick_sent, :realname,
                  :server, :port, :channels,
                  :username, :hostname,
                  :users

    # startup
    def initialize *args
      # set defaults
      @server   = "localhost"
      @port     = 6667
      @nick     = "irclient"
      @realname = "Irc::Client"
      @channels = []
      # automatics
      @username = Process.uid
      @hostname = Socket.gethostname
    end

    # send a message to user or channel
    def say to, message
      return message unless message
      message = message.to_s
      # for each line
      message.split("\n").each do |message|
        # send at chunks of 350 characters
        message.scan(/([^\n]*\n|.{1,350})/m){|chunk|
          send_data "PRIVMSG #{to} :#{chunk}\n"
        }
      end
      message
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
        @nick_sent = nick
        send_data "NICK #{nick}\n"
      end
    end

    #
    # User Callbacks
    #

    def _listen m
    end

    def _privmsg m
    end

    def _notice m
    end

    def _join m
    end

    def _part m
    end
  
    def _quit m
    end

    def _unknown m
    end

  end

end
