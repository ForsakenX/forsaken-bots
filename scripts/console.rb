#!/usr/bin/env ruby
ROOT  = File.dirname(__FILE__)+"/../"
$: << "#{ROOT}/lib/"
require 'rubygems'
require 'eventmachine'
require 'logger'
require 'yaml'
require "meth/meth.rb"
puts "Environment Loaded"
