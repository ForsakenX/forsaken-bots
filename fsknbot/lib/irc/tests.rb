#!/usr/bin/env ruby

# load path
$: << "../"

# bring in em
require "rubygems"
require "eventmachine-0.9.0/lib/eventmachine"

# bring in lib
require 'irc'

# test tools
def test bool
  if bool
    "passed"
  else
    "failed"
  end
end

# create user
user = Irc::User.create({
  :server   => 'irc.freenode.net',
  :host     => 'userhostname.com',
  :nick     => 'test',
  :user     => 'uid',
  :realname => 'test',
  :flags    => 'bullshit'
})

puts "Irc::User::create " + test(Irc::User.users.length == 1)

# join channel
user.join("#GSP!Forsaken")

# channels
puts "Irc::User#join " + test(
  user.channels.length == 1 &&
  Irc::Channel.channels.length == 1
)

# leave channel
user.leave("#GSP!Forsaken")

#
puts "Irc::User#leave " + test(user.channels.length == 0)

# remove a user
user.destroy

puts "Irc::User#destroy " + test(Irc::User.users.length == 0)

