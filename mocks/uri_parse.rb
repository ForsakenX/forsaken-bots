#!/usr/bin/env ruby

require 'net/http'

url = ARGV.shift
url = URI.parse(url)
puts url.to_s

