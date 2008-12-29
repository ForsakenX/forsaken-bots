#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'

# line protocol class
module EM::Protocols::LineText2

  # helper which adds a new line to send_data
  def send_line line
    send_data "#{line}\n"
  end

end

# this is the class clients connect to
class IrcProxy < EM::Connection
  include EM::Protocols::LineText2

  #
  # Class
  #
  
  # list of clients connected
  @@connections = []

  # send data to all clients
  def self.notify line
    @@connections.each {|c|c.send_line line}
  end

  #
  # Instance
  #

  # client expects all this input when it requests a join
  def bootstrap channel
    send_line(":FsknBot!n=x@localdomain JOIN :#{channel}",true)
    IrcClient.send_line "TOPIC #{channel}"
    IrcClient.send_line "NAMES #{channel}"
    IrcClient.send_line "MODE #{channel}"
  end

  # got client connect
  def post_init
    puts "--- Got client"
    @@connections << self
    # my bots expect 001 as a sign of succesfull login
    send_line ":FsknBot!n=x@localdomain 001 FsknBot :login success", true
    # send motd required for pidgin to see successful login
    send_line ":FsknBot!n=x@localdomain 375 FsknBot :MOTD", true
    send_line ":FsknBot!n=x@localdomain 372 FsknBot :- Welcome", true
    send_line ":FsknBot!n=x@localdomain 376 FsknBot :/MOTD", true
  end

  # lost a client
  def unbind
    puts "Lost client"
    @@connections.delete self
  end

  # receive data from client
  def receive_line line

    # catch join requests of client
    if line =~ /^JOIN :?([^ ]+)/i

      # boot strap #forsaken
      unless line.slice!(/,?#forsaken/i).nil?
        puts "c -> JOIN #forsaken"
        bootstrap '#forsaken'
      end

      # boot strap #6dof
      unless line.slice!(/,?#6dof/i).nil?
        puts "c -> JOIN #6dof"
        bootstrap '#6dof'
      end

      # do not allow clients to join other channels
      return
    end

    # do not allow client to make us quit
    if line =~ /^QUIT/i

      # kill the connection since client requests it
      @@connections.delete self
      puts "c -> #{line}"
      send_line "ERROR :Closing Link: hostname (Client Quit)", true
      close_connection_after_writing
      return

    end

    # blocked commands
    return if line =~ /^(PART|NICK|USER|PASS|AWAY|KICK|QUIT|JOIN)/i

    # forward input to irc
    IrcClient.send_line line

  end

  # send data to client
  def send_line line, print=false
    puts "c <- #{line}" if print
    super line
  end

end

# this is the class we use to connect to irc
class IrcClient < EM::Connection

  include EM::Protocols::LineText2

  #
  # Class
  #

  # our connection to irc server
  @@connection = nil

  # allows outside objects to send to irc
  def self.send_line line
    @@connection.send_line(line) unless @@connection.nil?
  end

  #
  # Instance
  #

  # we are connected to irc
  def post_init
    puts "Connected to freenode"
    @@connection = self
    send_line "PASS #{ARGV[0]}"
    send_line "USER x x x :x"
    send_line "NICK FsknBot"
    send_line "JOIN #forsaken,#6dof"
    #send_line "JOIN #6dof"
  end

  # we lost connectino to irc
  def unbind
    reconnect 'irc.freenode.net', 6667
    post_init
  end

  # irc has sent us data
  def receive_line line

    #
    # Bug
    #   Need to auto rejoin on part|kick|quit|error detections
    #

    # respond to pings
    if line =~ /^:[^ ]+ ping (.*)/im
      send_data "PONG #{$1}\n"
      return
    end

    # respond to version ctcp
    if line =~ /^:([^!]+)[^ ]+ PRIVMSG fsknbot :\001VERSION\001/i
      send_line "PRIVMSG #{$1} :Meth Proxy 0.1"
    end

    # privmsg detected
    if line =~ /^:([^!]+)[^ ]+ PRIVMSG ([^ ]+) :(.*)/im

      # only print channel and nick for readability
      puts "-> #{$2} #{$1}: #{$3}"

    # other types of input
    else

      # remove hostname from server lines for readability
      puts "-> #{line.sub(/^:[^ ]+ /,'')}"

    end

    # broadcast to clients
    IrcProxy.notify(line)

  end

  # print data sent to screen
  def send_line line
    send_data "#{line}\n"
    puts "<- #{line}"
  end

end

# run the server
EM::run {

  # connect to irc server
  EM::connect 'irc.freenode.net', 6667, IrcClient

  # listen for clients
  EM::start_server "127.0.0.1", 6667, IrcProxy

}

