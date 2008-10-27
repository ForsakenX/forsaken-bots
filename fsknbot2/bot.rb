#!/usr/bin/env ruby

## libraries
require 'rubygems'
require 'eventmachine'

## main settings
$nick    = 'fsknbot'
$channel = '#forsaken' #'#6dof'
$server  = 'localhost'
$port    = 6667

## constants
ROOT = File.dirname(__FILE__)

## lib path
$: << "#{ROOT}/lib/"
$: << "#{ROOT}/models/"
$: << "#{ROOT}/commands/"

## load lib and commands
Dir["lib/*.rb","models/*.rb","commands/*.rb"].each do |f|
  require f if FileTest.executable?(f)
end

## run servers
EM::run {

  ## connect to irc
  EM::connect $server, $port, IrcConnection

}

