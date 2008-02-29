#!/usr/bin/env ruby

require "../string.rb"

puts "Testing Regex Helpers"
regex_string = "/game/"
unless regex_string.parse_regex == "game"
  puts "Failed String#parse_regex"
  puts regex_string.parse
else
  puts "Passed String#parse_regex"
end
unless ((e=regex_string.test_regex) === true)
  puts "Failed String#text_regex"
  puts e
else
  puts "Passed String#test_regex"
end
