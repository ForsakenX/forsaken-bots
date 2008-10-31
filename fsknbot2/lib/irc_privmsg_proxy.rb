require 'irc_handle_line'
require 'em_protocols_line_text_2'

#
# Listens for chat lines
#

IrcHandleLine.events[:message].register do |args|
  next unless args[:to] == $channel
  next if args[:type] == "notice" # not suppose to respond to notices
  message = "#{args[:from]}: #{args[:message]}"
  puts "PrivmsgProxy >>> #{message}"
  IrcPrivmsgProxy.send_line message
end

#
# Class
#

class IrcPrivmsgProxy < EM::Connection
  class << self

    @@connections = []

    def send_line line
      @@connections.each{|c| c.send_line line }
    end

  end
end

#
# Instance
#   - only comes alive after sender sends a message
#   - upon connection you should say "hello <name>" to begin receiving lines
#

class IrcPrivmsgProxy < EM::Connection
  include EM::Protocols::LineText2
  def initialize
    status "Startup: sig => #{@signature}"
    @@connections << self
  end
  def unbind
    status "Lost Client #{@signature}"
  end
  def receive_line line
    puts "PrivmsgProxy <<< (#{@signature}): #{line}"
    IrcConnection.privmsg $channel, line
  end
end

