#!/usr/bin/ruby

ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"
require "tiny_url"

url = ARGV[0] || "google.com"
link = TinyUrl.new url

puts "tiny => #{link.tiny}"
puts "original => #{link.original}"

