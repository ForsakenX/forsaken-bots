require 'rubygems'
require 'eventmachine'

$nick     = 'fsknbot'
$nick_proper = 'FsknBot'
$channels = ['#forsaken'] #,'#6dof']
$server   = 'irc.freenode.net'
$port     = 6667
$prefix   = '!'
$passwd   = File.read "#{ROOT}/config/passwd"

$privmsg_channel = '#forsaken'
$privmsg_interface = '127.0.0.1'
$privmsg_port = 6668

# you must define these values in config file
$slack_incoming_hook = nil
$slack_bridge_token = nil
$slack_general_bot_token = nil
require "#{ROOT}/config/slack_config.rb"

$run_observers = []

$: << "#{ROOT}/lib/"
$: << "#{ROOT}/models/"
$: << "#{ROOT}/plugins/"

def puts_error file=nil, line=nil
  puts "--- ERROR: #{file} #{line}: (#{$!}):\n#{$@.join("\n")}"
end

begin
  Dir[
      # temporary hack because slack needs to
      # register observers before others
      "#{ROOT}/plugins/slack_bridge.rb",
      "#{ROOT}/lib/*.rb",
      "#{ROOT}/models/*.rb",
      "#{ROOT}/plugins/*.rb"
  ].each do |f|
    if FileTest.executable?(f)
      puts "Loading File: #{f}"
      require f
    else
      puts "Skipping File: #{f}"
    end
  end
rescue Exception
  puts_error(__FILE__,__LINE__)
  exit 1
end
