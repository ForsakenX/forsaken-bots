#!/usr/bin/ruby

require File.dirname(__FILE__) + '/test.lib'

$connection.receive_line ":user_1!n=uid@tester.com PRIVMSG #forsaken :!ping"

