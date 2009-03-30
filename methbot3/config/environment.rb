#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'

$nick     = 'methbot'
$nick_proper = 'MethBot'
$channels = ['#forsaken','#6dof']
$server   = 'irc.freenode.net'
$port     = 6667
$prefix   = '!'

$run_observers = [] # add procs to run when em is started

$: << "#{ROOT}/lib/"
$: << "#{ROOT}/models/"
$: << "#{ROOT}/plugins/"

def puts_error file=nil, line=nil
  puts "--- ERROR: #{file} #{line}: (#{$!}):\n#{$@.join("\n")}"
end

begin
  Dir[
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

