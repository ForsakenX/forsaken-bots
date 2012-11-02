#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test.lib'
require "google" # incase not executable

query = "cars"

puts GoogleCommand.search( query )

