#!/usr/bin/env ruby
require 'uri'
require 'net/http'
         url  = URI.parse('http://google.com/')
         req  = Net::HTTP::Get.new(url.path)
         http = Net::HTTP.start(url.host, url.port)
         res  = http.request(req)
         puts res.body
