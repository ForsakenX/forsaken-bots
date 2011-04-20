#!/usr/bin/env ruby
ROOT="./"
require 'lib/irc_command_manager'
require 'plugins/times'
class Usr
	def nick
		"methods"
	end
end
class Msg
	def from
		Usr.new
	end
	def args
		ARGV
	end
end
puts GameTimes.create(Msg.new)
puts GameTimes.show_all
