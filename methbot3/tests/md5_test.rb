#!/usr/bin/ruby

ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"
require "#{ROOT}/lib/feed"

puts md5( "test" )
