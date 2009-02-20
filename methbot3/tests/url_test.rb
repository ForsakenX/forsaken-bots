#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test.lib'
require 'url' # incase not executable

def get url
  puts Url.describe_link(url)
  puts "INFO:: " + Url.link_info(url)
  puts "TITLE:: " + Url.link_title(url)
end

get "http://en.wikipedia.org/wiki/Decimal_time"

