#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
agent = Mechanize.new
page = agent.get "http://google.com/search?q=#{ARGV.join(' ')}"
#results = page.links.select{|l| l.attributes['class']=='l' }
#results = page.links.select{|l| l.attributes['class'].nil? and !l.attributes['onmousedown'].nil? }

#link = page.links[59]
#puts link.inspect
#puts link.attributes.keys.inspect

require 'cgi'
puts page.links.select{|l|
	l.href =~ %r{^/url\?q=}
}.map{|l|
	CGI::unescape l.href.split('q=')[1].split('&')[0] 
}.inspect
