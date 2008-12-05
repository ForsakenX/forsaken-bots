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

    def privmsg target, messages
      [messages].flatten.each do |message|
        next if message.nil? or !message.respond_to?(:to_s) or message.empty?
        # shrink white space
        message.gsub!(/\s+/," ")
        # irc sends max of 512 bytes to sender
        # this should stop message from behind cut off
        message.to_s.scan(/.{1,230}[^ ]{0,150}/m){|chunk|
          # catch white space only lines
          next if chunk.gsub(/\s/,'').empty?
          # send the line
          IrcConnection.send_line "PRIVMSG #{target.downcase} :#{chunk}"
        }
      end
    end

    def chatmsg message
      IrcConnection.privmsg $channel, message
    end

    def who target
      IrcConnection.send_line "WHO #{target}"
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

  def receive_line line
    puts "irc >>> (fsknbot2) #{line}"
    close_connection if line.split.first.downcase == "error"
    IrcHandleLine.new line
  rescue Exception
    puts_error __FILE__,__LINE__
  end

end

