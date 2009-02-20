#!/usr/bin/ruby

require File.dirname(__FILE__) + '/test.lib'
require 'chatter' # incase not executable

def info msg
	puts "*"*50
	puts msg
end

class FakeMessage
class << self

	@@args = []
	def args; @@args; end
	def args= x; @@args = x; end

	def reply msg=""
		puts "reply => #{msg}"
	end
end
end

=begin
info "Testing No Args "
IrcCommandManager.call( 'chatter', FakeMessage )

info "Testing W/ Args "
FakeMessage.args = ['wotd']
IrcCommandManager.call( 'chatter', FakeMessage )

info IrcCommandManager.help[ "chatter" ]

info "WOTD: #{Chatter.wotd}"

info "FQOTD: #{Chatter.fqotd}"

info "QOTD: #{Chatter.qotd}"

info "JOTD: #{Chatter.jotd}"

info "Fortune: #{Chatter.fortune}"
=end

3.times do
	info "Random: #{Chatter.random}"
end

