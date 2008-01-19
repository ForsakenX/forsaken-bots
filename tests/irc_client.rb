#!/usr/local/bin/ruby

# settings

$username = "localuser"
$hostname = "localhost"
$server   = "irc.freenode.net"
$port     = 6667
$realname = "methods on ruby"
$nick     = "methods[cli]"
$version  = "Minimal Ruby Irc Client version 0.00"
$channels = ["#forsaken"]

#####

require 'rubygems'
require 'eventmachine'

# event class used for our connection
class IrcClient < EM::Connection

  #
  # Modules
  #

  # line based protocol
  include EM::Protocols::LineText2

  #
  # Events
  #

  # connection established event
  def post_init
    user $username, $hostname, $server, $realname
    nick $nick
    $channels.each do |channel|
      join channel
    end
  end

  # connection has been closed
  def unbind
    puts "[NOTICE] connection closed..."
    puts "[NOTICE] reconnecting..."
    reconnect $server, $port
    post_init
  end

  # new line recieved
  def receive_line line
    case line
    # ping/pong
    when /^PING ([^ ]*)/i
      pong $1
    # privmsg or notice
    when /^:(([^!]+)!([^ ]+)) (PRIVMSG|NOTICE) ([^ ]+) :([^$]+)$/i
      hostmask = $1
      sender   = $2
      host     = $3
      type     = $4
      target   = $5
      message  = $6
      # ctcp
      if message =~ /\001([^\001]*)\001/
        # auto respond
        case $1
        when /VERSION/i
          ctcp sender, $version
        when /PING ([^ ]+)/i
          ctcp sender, "PONG #{$1}"
        end
      # normal privmsg|notice
      else
        # display formated
        output  = "#{target} #{Time.now.strftime("(%I:%M:%S:%p)")} #{sender}: "
        output += "(notice) " if type == "NOTICE"
        output += "#{message}"
        puts output
      end
    # unhandeled input
    else
      puts "> #{line}"
    end
  end

  #
  # Helpers
  #

  def user username, hostname, server, realname
    if [username,hostname,server,realname].include? nil
      puts "[ERROR] user() expects username,hostname,server,realname arguments"
      return false
    end
    send_data "USER #{username} #{hostname} #{server} :#{realname}\r\n"
  end

  def nick nick=nil
    if nick.nil?
      puts "[ERROR] nick() expects nick argument"
      return false
    end
    send_data "NICK #{nick}\r\n"
  end

  def who target=nil
    if target.nil?
      puts "[ERROR] who() expects target argument"
      return false
    end
    send_data "WHO #{target}\r\n"
  end

  def join channel=nil
    if channel.nil?
      puts "[ERROR] join() expects channel argument"
      return false
    end
    send_data "JOIN #{channel}\r\n"
    @last_join = channel.downcase
  end

  def part channel=nil, message=nil
    if channel.nil?
      puts "[ERROR] part() expects channel argument"
      return false
    end
    send_data "PART #{channel} :#{message}\r\n"
  end

  def privmsg target, message=nil
    message = message.to_s if message.respond_to?(:to_s)
    unless message
      puts "[ERROR] privmsg() expects a target and message argument"
      return false
    end
    # for each line
    message.split("\n").each do |message|

      # 512bytes per send to >> irc >> client
      # must calculate hostname
      # 100bytes overhead is plenty and leaves 412 left
      # code below goes up to 400... safe enough
      
      # need a way to throttle 1500bytes within 2 seconds
      # other wise you get flood kick

      # send at chunks of 350 characters
      # scan up target extra 50 non space characters
      # biggest word in english language is 45 characters
      # this stargetps worsd from getting cut up
      
      message.scan(/.{1,350}[^ ]{0,50}/m){|chunk|
        next if chunk.length < 1
        send_data "PRIVMSG #{target} :#{chunk}\r\n"
      }

    end
    puts "#{target} #{Time.now.strftime("(%I:%M:%S:%p)")} #{$nick}: #{message}"
    message
  end

  alias :msg :privmsg

  def say message=nil
    privmsg @last_join, message
  end

  def notice target=nil, message=nil
    if target.nil? || message.nil?
      puts "[ERROR] notice() expects a target and message argument"
      return false
    end
    send_data "NOTICE #{target} :#{message}\r\n"
    puts "#{target} #{Time.now.strftime("(%I:%M:%S:%p)")} #{$nick}: #{message}"
  end

  def ctcp target=nil, message=nil, type="notice"
    if message.nil? || target.nil?
      puts "[ERROR] ctcp() expects target and message arguments"
      return false
    end
    message = "\001#{message}\001"
    case type
    when "notice"
      notice target, message
    when "privmsg"
      privmsg target, message
    else
      puts "[ERROR] ctcp() expects type argument to be one of notice or privmsg"
    end
  end

  def names channel=nil
    send_data "NAMES #{channel||@last_join}\r\n"
  end

  def ping token=nil
    send_data "PING #{token||Time.now.to_i}\r\n"
  end

  def pong token=nil
    if token.nil?
      puts "[ERROR] ping() requires token argument"
      return false
    end
    send_data "PONG #{token.to_s}\r\n"
  end

  def quit message=nil
    send_data "QUIT :#{message}\r\n"
    EM::stop_event_loop
  end

end

# keyboard event class
class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2
  def receive_line line
    line = line.chomp
    begin
      # eval pure code in connection instance
      # if first character is a forward slash
      # if its a exclamation character then send output with say command
      if line.slice!(/^(\/|!)/)
        output = $object.instance_eval(line)
        if $1 == "!"
          $object.send(:say, output)
        end
      # invoke say command
      # which sends a privmsg to last joined channel
      else
        $object.send(:say, line)
      end
    rescue Exception
      puts "[ERROR]"
      puts "\t#{$!}"             # description
      puts $@.map{|s|"\t#{s}\n"} # trace
      puts "[END]"
    end
  end
end

# run the EM server
# this blocks until finished
# each EM call inside does not block
EM::run {

  # make a connect to irc freenode using our Irc event class above
  EM::connect($server,$port,IrcClient){|o|
    # catch refrence to connection object
    # so we can eval keyboard input within it
    $object = o
  }

  # open keyboard for inputs
  EM.open_keyboard(KeyboardHandler)

}


