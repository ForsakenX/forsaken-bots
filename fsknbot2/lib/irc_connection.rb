require 'irc_handle_line'
require 'em_protocols_line_text_2'

#
# Public API
#

class IrcConnection < EM::Connection
  class <<self

    @@connection = nil

    def send_line line
      @@connection.send_line line unless @@connection.nil?
    end

    def close
      @@connection.close_connection unless @@connection.nil?
    end

    def privmsg target, message
      IrcConnection.send_line "PRIVMSG #{target.downcase} :#{message}"
    end

    def chatmsg message
      IrcConnection.privmsg $channel, message
    end

    def who target
      IrcConnection.send_line "WHO #{target}"
    end

    def topic str
      IrcConnection.send_line "TOPIC #{$channel} :#{str}"
    end

  end
end

#
#  Instance
#

class IrcConnection < EM::Connection

  include EM::Protocols::LineText2

  def initialize
    status "Startup"
  end

  def post_init
    status "Connected"
    @@connection = self
    send_line "JOIN #{$channel}"
  end

  def unbind
    status "Disconnected"
    reconnect $server, $port
    post_init
  end

  def send_line line
    return if line.nil? or line.empty? or !line.respond_to?(:to_s)
    puts "irc <<< #{line}"
    message = message.to_s
    # irc sends max of 512 bytes to sender
    # this should stop message from behind cut off
    message.scan(/.{1,280}[^ ]{0,100}/m){|chunk|
      send_line chunk unless chunk.length < 1
    }
  end

  def receive_line line
    puts "irc >>> (fsknbot2) #{line}"
    close_connection if line.split.first.downcase == "error"
    IrcHandleLine.new line
  rescue Exception
    puts_error __FILE__,__LINE__
  end

end

