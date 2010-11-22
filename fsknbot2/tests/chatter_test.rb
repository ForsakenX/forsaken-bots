#!/usr/bin/ruby

require File.dirname(__FILE__) + '/test.lib'
require 'chatter' # incase not executable

def info msg
	puts "*"*50
	puts msg
end

#info IrcCommandManager.help[ "chatter" ]

#info "WOTD: #{Chatter.wotd}"
#info "FQOTD: #{Chatter.fqotd}"
#info "QOTD: #{Chatter.qotd}"
#info "JOTD: #{Chatter.jotd}"
#info "LimeRick: #{Chatter.limerick}"
#info "Linux: #{Chatter.linux}"

100.times{info "Random: #{Chatter.random}"}

