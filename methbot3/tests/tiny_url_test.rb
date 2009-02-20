#!/usr/bin/ruby

require File.dirname(__FILE__) + '/test.lib'
require "tiny_url" # incase not executable

url = ARGV[0] || "google.com"
link = TinyUrl.new url

puts "tiny => #{link.tiny}"
puts "original => #{link.original}"

