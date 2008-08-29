#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'

module EM::Protocols::LineText2
  def send_line line
    send_data "#{line}\n"
  end
end

class IrcProxy < EM::Connection
  include EM::Protocols::LineText2
  #
  # Class
  #
  @@connections = []
  def self.notify line
    @@connections.each do |connection|
      connection.send_line line
    end
  end
  #
  # Instances
  #
  def bootstrap channel
    # join to forsaken
    send_line(":FsknBot!n=x@localdomain JOIN :#{channel}",true)
    # client also needs all this data
    # all of this data is automatically sent on joins
    IrcClient.send_line "TOPIC #{channel}"
    IrcClient.send_line "NAMES #{channel}"
    IrcClient.send_line "MODE #{channel}"
  end
  def post_init
    puts "--- Got client"
    @@connections << self
    # custom auth notice
    send_line "NOTICE AUTH :*** You do not need to authenticate"
    send_line "NOTICE AUTH :*** Proxy is already authenticated"
    # my bots expect this
    send_line ":FsknBot!n=x@localdomain 001 FsknBot :login success", true
    # send motd
    send_line ":FsknBot!n=x@localdomain 375 FsknBot :- localhost message of the day -", true
    send_line ":FsknBot!n=x@localdomain 372 FsknBot :- Welcome to Meth Proxy", true
    send_line ":FsknBot!n=x@localdomain 376 FsknBot :End of /MOTD command.", true
    # bootstrap channels
    # just program your bots to join them
    #bootstrap '#forsaken'
    #bootstrap '#6dof'
  end
  def unbind
    puts "Lost client"
    @@connections.delete self
  end
  def receive_line line
    # catch join messages to channels we are in already
    # since are already joined these commands will do nothing
    if line =~ /^JOIN :?([^ ]+)/i
      unless line.slice!(/,?#forsaken/i).nil?
        puts "client >>> JOIN #forsaken"
        bootstrap '#forsaken'
      end
      unless line.slice!(/,?#6dof/i).nil?
        puts "client >>> JOIN #6dof"
        bootstrap '#6dof'
      end
      # if there is no more channels in the argument
      # then don't send an empty join message
      return unless line =~ /^JOIN :?([^ ]+)$/i
    end
    # don't allow bad clients to part us from main rooms
    if line =~ /^PART/i
      line.gsub!(/,?(#forsaken|#6dof)/,'')
      # don't send empty part command
      return if line =~ /^PART $/i
    end
    # don't allow bad bots to make us quit
    if line =~ /^QUIT/i
      @@connections.delete self
      puts "client >>> #{line}"
      send_line "ERROR :Closing Link: hostname (Client Quit)", true
      close_connection_after_writing
      return
    end
    # don't allow bots to change our nick
    if line =~ /^NICK (.*)/i
      puts "client >>> #{line}"
      if $1.downcase != "fsknbot"
        send_line ":FsknBot!n=x@localdomain 432 FsknBot #{$1} :"+
                  "Client not allowed to change nick", true
      end
      return
    end
    # these should only be sent at startup
    action = line.split(' ').first
    if !action.nil? && %{user pass}.include?(action.downcase)
      puts "client >>> #{line}"
      return
    end
    # send line to irc
    IrcClient.send_line line
  end
  def send_line line, print=false
    puts "client <<< #{line}" if print
    super line
  end
end

class IrcClient < EM::Connection
  include EM::Protocols::LineText2
  #
  # Class
  #
  @@connection = nil
  def self.send_line line
    @@connection.send_line(line) unless @@connection.nil?
  end
  #
  # Instance
  #
  def post_init
    puts "Connected to freenode"
    @@connection = self
    send_line "PASS #{ARGV[0]}"
    send_line "USER x x x :x"
    send_line "NICK FsknBot"
    send_line "JOIN #forsaken,#6dof"
  end
  def unbind
    reconnect 'irc.freenode.net', 6667
    post_init
  end
  def receive_line line
    # respond to pings
    if line =~ /^:[^ ]+ ping (.*)/im
      send_data "PONG #{$1}\n"
      return
    end
    # respond to version ctcp
    if line =~ /^:([^!]+)[^ ]+ PRIVMSG fsknbot :\001VERSION\001/i
      send_line "PRIVMSG #{$1} :Meth Proxy 0.1"
    end
    # print to the screen
    if line =~ /^:([^!]+)[^ ]+ PRIVMSG ([^ ]+) :(.*)/im
      # only print user name for readability
      puts "irc >>> #{$2} #{$1}: #{$3}"
    else
      # remove hostname from server lines for readability
      puts "irc >>> #{line.sub(/^:[^ ]+ /,'')}"
    end
    # broadcast to clients
    IrcProxy.notify(line)
  end
  def send_line line
    send_data "#{line}\n"
    puts "irc <<< #{line}"
  end
end

EM::run {
  EM::connect 'irc.freenode.net', 6667, IrcClient
  EM::start_server "0.0.0.0", 6667, IrcProxy
}

