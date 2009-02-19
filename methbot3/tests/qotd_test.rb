#!/usr/bin/ruby

ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"
require "qotd"

100.times{ puts QOTD.random }

