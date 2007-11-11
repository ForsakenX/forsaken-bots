# $Id: test_basic.rb 500 2007-08-17 09:45:20Z blackhedd $
#
# Author:: Francis Cianfrocca (gmail: blackhedd)
# Homepage::  http://rubyeventmachine.com
# Date:: 8 April 2006
# 
# See EventMachine and EventMachine::Connection for documentation and
# usage examples.
#
#----------------------------------------------------------------------------
#
# Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
# Gmail: blackhedd
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of either: 1) the GNU General Public License
# as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version; or 2) Ruby's License.
# 
# See the file COPYING for complete licensing information.
#
#---------------------------------------------------------------------------
#
#
# 

$:.unshift "../lib"
require 'eventmachine'

class TestBasic < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  #-------------------------------------

  def test_libtype
    lt = EventMachine.library_type
    case $eventmachine_library
    when :pure_ruby
      assert_equal( :pure_ruby, lt )
    when :extension
      assert_equal( :extension, lt )
    when :java
      assert_equal( :java, lt )
    else
      assert_equal( :extension, lt )
    end
  end

  #-------------------------------------


  def test_em
    EventMachine.run {
      EventMachine.add_timer 0 do
        EventMachine.stop
      end
    }
  end

  #-------------------------------------

  def test_timer
    n = 0
    EventMachine.run {
      EventMachine.add_periodic_timer(1) {
        n += 1
        EventMachine.stop if n == 2
      }
    }
  end

  #-------------------------------------

  # This test once threw an already-running exception.
  module Trivial
    def post_init
      EventMachine.stop
    end
  end

  def test_server
    EventMachine.run {
      EventMachine.start_server "localhost", 9000, Trivial
      EventMachine.connect "localhost", 9000
    }
    assert( true ) # make sure it halts
  end

  #--------------------------------------

  # EventMachine#run_block starts the reactor loop, runs the supplied block, and then STOPS
  # the loop automatically. Contrast with EventMachine#run, which keeps running the reactor
  # even after the supplied block completes.
  def test_run_block
	  a = nil
	  EM.run_block { a = "Worked" }
	  assert a
  end


  #--------------------------------------

end


