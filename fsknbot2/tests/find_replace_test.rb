#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/test.lib'

# include FindReplace incase it's not executable yet
# it registers it self as a listener for IrcChatMsg
require 'find_replace.rb'

puts "creating a last message"
IrcChatMsg.new({ :from => "user_1", :to => "#forsaken", :message => "bla bla bla" })

puts "s/bla/bloo"
IrcChatMsg.new({ :from => "user_1", :to => "#forsaken", :message => "#{$prefix}s/bla/bloo" })

puts "broken find s/\#{bla}/bloo/g"
find='#{bla}'

def $connection.send_line msg=""
end

IrcChatMsg.new({ :from => "user_1", :to => "#forsaken", :message => "#{$prefix}s/#{find}/bloo" })

puts "done testing"
