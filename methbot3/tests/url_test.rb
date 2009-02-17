#!/usr/bin/env ruby

ROOT = File.dirname(__FILE__) + "/../"

$: << "#{ROOT}/lib/"
$: << "#{ROOT}/models/"
$: << "#{ROOT}/plugins/"

require 'rubygems'
require 'eventmachine'
require 'irc_command_manager'
require 'irc_chat_msg.rb'
require 'irc_user'
require 'url'

def puts_error file=nil, line=nil
  puts "--- ERROR: #{file} #{line}: (#{$!}):\n#{$@.join("\n")}"
end

class FakeMessage
	def initialize
	end
	def reply message
		puts message
	end
	def from
		IrcUser.new({:nick => 'fake_user', :host => ""})
	end
	def to
		"fake_target"
	end
	def time
		Time.now
	end
end

m = FakeMessage.new

url = "http://en.wikipedia.org/wiki/Decimal_time"

UrlCommand.check_url( m, url )

