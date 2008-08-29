#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'

class Irc < EM::Connection
  include EM::Protocols::LineText2
  def post_init
  end
  def unbind
    reconnect "localhost", "6667"
    post_init
  end
  def send_line line
    puts "irc <<< #{line}"
    send_data "#{line}\n"
  end
  def receive_line line
    puts "irc >>> #{line}"
    parts = line.split(' ')
    action = parts.shift
    # error bla bla
    if action == "error"
      disconnect
      return
    end
    # ping :token
    if action == "ping"
      send_line "PONG "+parts.shift
      return
    end
    # nick!uid@hostname
    source_mask = action.sub(':','').downcase
    source_host = source_mask.split('@')[1]
    source_nick = source_mask.split('@')[0].split('!')[0]
    source_uid  = source_mask.split('@')[0].split('!')[1]
    action = parts.shift.downcase
    # privmsg target :message
    if action == "privmsg"
      target = parts.shift
      channel = (target[0] == "#"[0])
      message = parts.join(' ').sub(/^:/,'')
      new_target = channel ? target : source_mask
      if message == "maybe"
        send_line "PRIVMSG #{new_target} :Kinda!"
        return
      end
      return
    end
  end
end

EM::run {
  EM::connect "localhost", 6667, Irc
}

