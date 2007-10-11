#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'

# the root
ROOT = ARGV[0]||"."
puts "ROOT set to #{ROOT}"

# load library
require 'irc'
puts "Loaded irc.rb"

# run the thing
def em_run handler
  begin
    handler.servers.each do |server|
      (server,port) = server.split(':')
      puts "Starting #{handler.em_type.to_s} => #{server.to_s} : #{port.to_s}"
      case handler.em_type
      when :server
        EM::start_server(server, port.to_i, handler)
      when :client
        EM::connect(server, port.to_i, handler)
      else
        puts "Unknown type for #{handler}"
      end
    end
  rescue EventMachine::ConnectionNotBound
    puts "Connection Not Bound: #{$!}"
  rescue
    puts "Unknown Error: #{$!}"
    $@.each do |line|
      puts "#{line}"
    end
  end
end


