# $Id: test_next_tick.rb 381 2007-06-15 19:48:11Z blackhedd $
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
#

$:.unshift "../lib"
require 'eventmachine'



class TestNextTick < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_tick_arg
		pr = proc {EM.stop}
		EM.epoll
		EM.run {
			EM.next_tick pr
		}
		assert true
	end

	def test_tick_block
		EM.epoll
		EM.run {
			EM.next_tick {EM.stop}
		}
		assert true
	end
end
