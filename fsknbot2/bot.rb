#!/usr/bin/env ruby

# libraries
require 'rubygems'
require 'eventmachine'

# main settings
$nick    = 'fsknbot'
$channel = '#forsaken' #'#6dof'
$server  = 'localhost'
$port    = 6667
$prefix  = '!'
$privmsg_port = 6668

# start observers
$run_observers = []

# constants
ROOT = File.dirname(__FILE__)

# lib path
$: << "#{ROOT}/lib/"
$: << "#{ROOT}/models/"
$: << "#{ROOT}/commands/"

# load lib and commands
Dir["lib/*.rb","models/*.rb","commands/*.rb"].each do |f|
  require f if FileTest.executable?(f)
end

# error helper
def puts_error file=nil, line=nil
  puts "--- ERROR: #{file} #{line}: (#{$!}):\n#{$@.join("\n")}"
end

# catch errors
module EM
  def handle_runtime_error
    puts_error __FILE__,__LINE__
  end
end

# run servers
EM::run {

  ## connect to irc
  EM::connect $server, $port, IrcConnection

  ## privmsg proxy
  EM::start_server $server, $privmsg_port, IrcPrivmsgProxy

  ## tell people we are now running
  $run_observers.each{|o|o.call}

}

