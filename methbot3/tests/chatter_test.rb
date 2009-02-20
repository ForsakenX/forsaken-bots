#!/usr/bin/ruby

# boot strap environment
ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"
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

info "Testing No Args "
IrcCommandManager.call( 'chatter', FakeMessage )

info "Testing W/ Args "
FakeMessage.args = ['wotd']
IrcCommandManager.call( 'chatter', FakeMessage )

=begin

info IrcCommandManager.help[ "chatter" ]

info "WOTD: #{Chatter.wotd}"

info "FQOTD: #{Chatter.fqotd}"

info "QOTD: #{Chatter.qotd}"

info "JOTD: #{Chatter.jotd}"

info "Fortune: #{Chatter.fortune}"

3.times do
	info "Random: #{Chatter.random}"
end

=end

