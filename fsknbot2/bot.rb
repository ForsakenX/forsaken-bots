#!/usr/bin/env ruby

# libraries
require 'rubygems'
require 'eventmachine'

# main settings
$nick     = 'fsknbot'
$nick_proper = 'FsknBot'
$channels = ['#forsaken']
$server   = 'irc.freenode.net'
$port     = 6667
$prefix   = '!'
$privmsg_port = 6668

# start observers
$run_observers = []

# constants
ROOT = File.dirname(__FILE__)

# lib path
$: << "#{ROOT}/lib/"
$: << "#{ROOT}/models/"
$: << "#{ROOT}/plugins/"

# error helper
def puts_error file=nil, line=nil
  puts "--- ERROR: #{file} #{line}: (#{$!}):\n#{$@.join("\n")}"
end

# load lib and commands
begin
  Dir[
      "lib/*.rb",
      "models/*.rb",
      "plugins/*.rb"
  ].each do |f|
    puts "Loading File: #{f}"
    require f if FileTest.executable?(f)
  end
rescue Exception
  puts_error(__FILE__,__LINE__)
  exit 1
end

# catch errors
module EM
  def handle_runtime_error
    puts_error __FILE__,__LINE__
  end
end

# run servers
EM::run {

  begin
    ## connect to irc
    EM::connect $server, $port, IrcConnection
  rescue Exception
    puts_error(__FILE__,__LINE__)
    exit 1
  end

  ## tell people we are now running
  $run_observers.each{|o|o.call}

}

