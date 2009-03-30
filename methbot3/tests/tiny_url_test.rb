#!/usr/bin/ruby

require File.dirname(__FILE__) + '/test.lib'
require "tiny_url" # incase not executable

url = ARGV[0] || "http://google.com"
link = TinyUrl.new url

puts "tiny => #{link.tiny}"
puts "original => #{link.original}"
puts "post.url => #{link.post['url']}"

require 'url'
page = Url.get( link.tiny )
puts page.uri.to_s
puts page.uri.path

