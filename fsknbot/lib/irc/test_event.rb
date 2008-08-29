#!/usr/bin/env ruby

# load path
$: << "../"

# logger
require 'logger'

# bring in em
require "rubygems"
require "eventmachine-0.9.0/lib/eventmachine"

# bring in lib
require 'irc'

event = Irc::Event.new

one = Proc.new{
  puts "one"
  two = Proc.new{
    puts "two"
  }
  event.register('one',two)
}
event.register('one',one)

event.call('one',nil)

