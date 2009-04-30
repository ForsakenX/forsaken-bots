#!/usr/bin/env ruby

# root directory
ROOT = File.dirname(__FILE__)

# configuration file
require "#{ROOT}/config/environment"

# run servers
EM::run {

  begin
    EM::connect $server, $port, IrcConnection
    EM::start_server $privmsg_interface, $privmsg_port, IrcPrivmsgProxy
  rescue Exception
    puts_error(__FILE__,__LINE__)
    exit 1
  end

  # startup notifications
  $run_observers.each{|o|o.call}

}

