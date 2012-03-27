#!/usr/bin/env ruby

$stdout.sync = true # disable output buffering
$stderr.sync = true # disable output buffering

ROOT = File.dirname(__FILE__)

require "#{ROOT}/config/environment"

module EM
  def handle_runtime_error
    puts_error __FILE__,__LINE__
  end
end

EM::run {
  begin
    EM::connect $server, $port, IrcConnection
	  #EM::start_server $privmsg_interface, $privmsg_port, IrcPrivmsgProxy
  rescue Exception
    puts_error(__FILE__,__LINE__)
    exit 1
  end
  $run_observers.each{|o|o.call}
}
