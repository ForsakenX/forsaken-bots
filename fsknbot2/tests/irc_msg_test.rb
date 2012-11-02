#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test.lib'

message = IrcChatMsg.new({
	:from => "user_1",
	:to => "#forsaken",
	:message => "!testing 123",
})

puts message.inspect


