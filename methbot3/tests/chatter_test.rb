#!/usr/bin/ruby

# boot strap environment
ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"
require 'chatter' # incase not executable

class Object
	def puts msg=""
		super "*"*50
		super msg
	end
end

puts Chatter.fortune

puts Chatter.qotd

3.times do
	puts Chatter.random
end

