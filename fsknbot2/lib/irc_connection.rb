require 'observe'
require 'irc_handle_line'
require 'em_protocols_line_text_2'

#
# Public API
#

class IrcConnection < EM::Connection
  class <<self

    @@events = {
      :privmsg => Observe.new,
    }

    def events; @@events; end

    @@connection = nil
    @@last_ping_time = Time.now
    def last_ping_time; @@last_ping_time; end
    def last_ping_time=(x); @@last_ping_time=x; end

    @@last_pong_time = Time.now
    def last_pong_time; @@last_pong_time; end
    def last_pong_time=(x); @@last_pong_time=x; end

    def send_line line
      @@connection.send_line line unless @@connection.nil?
    end

    def close
      @@connection.close_connection unless @@connection.nil?
    end

    def privmsg targets, messages, type="PRIVMSG"
      @@events[:privmsg].call(targets,messages)
      privmsg_raw targets, messages, type
    end

    def privmsg_raw targets, messages, type="PRIVMSG"
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
          [targets].flatten.each do |target|
            IrcConnection.send_line "#{type} #{target.downcase} :#{chunk}"
          end
        }
      end
    end

    def chatmsg channel, message, type="PRIVMSG"
      IrcConnection.privmsg channel, message, type
    end

    def who target
      IrcConnection.send_line "WHO #{target}"
    end

    def topic channel, str
      IrcConnection.send_line "TOPIC #{channel} :#{str}"
    end

    def join channels
      [channels].flatten.each do |channel|
        IrcConnection.send_line "JOIN #{channel}"
      end
    end

    def kick nick, message="pwned!", channel="#forsaken" 
      IrcConnection.send_line "KICK #{channel} #{nick} :#{message}"
    end

    def pong token
      @@last_ping_time = Time.now
      IrcConnection.send_line "PONG #{token}"
    end

    def ping token
      IrcConnection.send_line "PING #{token}"
    end

  end
end

# if we haven't received a pong in 5 minutes
# then close the connection which will invoke reconnect in `unbind`
$run_observers << Proc.new {

  # set initial time to future so it lines up with timer
  IrcConnection.last_pong_time = Time.now + 60

  # add a timer for every minute
  EM::PeriodicTimer.new( 60 ) do

    # send a ping and expect a pong response
    IrcConnection.ping Time.now.to_i

# TODO - could change this later to use a one-time-timer
#        that verifies that the token we went above is sent back

    # retart connection if we don't see pong response in a reasonable time
    # ping responses are usually rather instant
    if Time.now - IrcConnection.last_pong_time > 60*2
      IrcConnection.last_pong_time = Time.now
      puts "CLOSING CONNECTION - last pong was at #{IrcConnection.last_pong_time}"
      IrcConnection.close
    end

  end

}

=begin
# if we haven't received a ping in 5 minutes
# then close the connection which will invoke reconnect in `unbind`
$run_observers << Proc.new {
  EM::PeriodicTimer.new( 60 ) do
    if Time.now - IrcConnection.last_ping_time > 60*5
      IrcConnection.last_ping_time = Time.now
      puts "CLOSING CONNECTION - last ping was at #{IrcConnection.last_ping_time}"
      IrcConnection.close
    end
  end
}
=end

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
    send_line "PASS #{$passwd}"
    send_line "USER x x x :x"
    send_line "NICK #{$nick_proper}"
    IrcConnection.join $channels
  end

  def unbind
    status "Disconnected"
    sleep 1
    reconnect $server, $port
    post_init
  end

  def receive_line line
    t=Time.now
    puts
    puts "irc #{t.strftime("%m-%d-%y %H:%M:%S")} >>> (fsknbot2) #{line}"
    close_connection if line.split.first.downcase == "error"
    IrcHandleLine.new line
    puts "Took #{Time.now-t} seconds to process line."
    puts
  rescue Exception
    puts_error __FILE__,__LINE__
  end

end

