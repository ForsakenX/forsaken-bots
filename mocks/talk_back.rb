#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'

module TalkBack
  def receive_data data
    send_data "You said #{data}"
  end
end

EM::run {
  EM::start_server "127.0.0.1", 80000, TalkBack
}

