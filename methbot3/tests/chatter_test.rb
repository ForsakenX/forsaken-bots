#!/usr/bin/ruby

# boot strap environment
ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"
require 'chatter' # incase not executable

3.times{ puts Chatter.random }

