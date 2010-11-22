#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test.lib'
require 'url' # incase not executable

def get url
  puts '-'*50
  puts "URL:: " + url
  puts "-----------"
  puts "DESCRIBE:: " + Url.describe_link(url).to_s
#  puts "-----------"
#  puts "INFO:: " + Url.link_info(url).to_s
#  puts "-----------"
#  puts "TITLE:: " + Url.link_title(url).to_s
end

#get "http://fly.thruhere.net/versions/test.html"
get "http://fly.thruhere.net"
#get "http://en.wikipedia.org/wiki/Decimal_time"
#get "http://fly.thruhere.net/versions/ProjectX_1.04.701.exe"

