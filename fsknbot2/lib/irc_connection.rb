require 'irc_handle_line'
require 'em_protocols_line_text_2'
class IrcConnection < EM::Connection

  ## line protocol helpers
  include EM::Protocols::LineText2

  ## reference to connection
  @@connection = nil

  ## outside api
  class <<self

    ## send data to active connection
    def send_line data
      @@connection.send_line data unless @@connection.nil?
    end

    ## close connection
    def close
      @@connection.close_connection unless @@connection.nil?
    end

    # privmsg helper
    def privmsg target, message
      IrcConnection.send_line "PRIVMSG #{target} :#{message}"
    end

    # send to $channel
    def chatmsg message
      IrcConnection.privmsg $channel, message
    end

    # send who message
    def who target
      IrcConnection.send_line "WHO #{target}"
    end

    # send topic
    def topic data
      IrcConnection.send_line "TOPIC #{$channel} :#{data}"
    end

  end

  ## startup
  def initialize
    status "Startup"
  end

  ## successfull connection
  def post_init
    status "Connected"
    @@connection = self
    send_line "JOIN #{$channel}"
  end

  ## connection lost
  def unbind
    status "Disconnected"
    reconnect $server, $port
    post_init
  end

  ## line has been received
  def receive_line line
  
    ## print data to console
    puts "irc >>> (fsknbot2) #{line}"

    ## if server sent error
    close_connection if line.split.first.downcase == "error"

    ##  pass to line handler
    IrcHandleLine.new line

  rescue Exception

    puts_error

  end

end
