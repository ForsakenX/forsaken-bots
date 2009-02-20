#!/usr/bin/ruby

ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"
require "google"

query = "cars"
puts GoogleCommand.search( query )

