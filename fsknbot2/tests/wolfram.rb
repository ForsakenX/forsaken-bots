#!/usr/bin/env ruby
require 'nokogiri'
require 'open-uri'
require 'uri'
query = "http://api.wolframalpha.com/v1/query?appid=K857H8-5YUX4WQ8PW&input="
input = URI.escape ARGV.join(' ')
doc =  Nokogiri::XML open(query + input)
puts doc.inspect
#puts doc.css('queryresult').first.attributes['success'].value
if doc.css('queryresult').first.attributes['success'].value == "false"
	puts "Query Failed: " + doc#.css('error msg').text
else
	puts "Query Succeeded: " +doc#.css('pod[id="Result"] plaintext').text
end
