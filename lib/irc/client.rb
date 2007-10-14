  
  # handle irc
  require 'socket'
  class Irc::Client < EM::Connection

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
      Irc::HandleMessage.new(self,line)
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

