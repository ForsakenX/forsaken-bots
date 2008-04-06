#!/usr/bin/env ruby

require 'net/http'

url = ARGV.shift
url = "http://#{url}" unless url =~ /^http:\/\//

url      = URI.parse(url)
http     = Net::HTTP.new(url.host,url.port)
response = http.request_get(url.request_uri,{"User-Agent"=>"FsknBot"})

puts response.class.name

puts response.content_type
puts response.content_length
puts response.message
puts response.body
#puts response.methods.join(', ')

puts response.header["Location"]

