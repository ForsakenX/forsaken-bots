# $Id: jeventmachine.rb 451 2007-07-21 13:34:28Z blackhedd $
#
# Author:: Francis Cianfrocca (gmail: blackhedd)
# Homepage::  http://rubyeventmachine.com
# Date:: 8 Apr 2006
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


# This module provides "glue" for the Java version of the EventMachine reactor core.
# For C++ EventMachines, the analogous functionality is found in ext/rubymain.cpp,
# which is a garden-variety Ruby-extension glue module.


require 'em_reactor'

module EventMachine
	# TODO: These event numbers are defined in way too many places.
	# DRY them up.
	TimerFired = 100
	ConnectionData = 101
	ConnectionUnbound = 102
	ConnectionAccepted = 103
	ConnectionCompleted = 104
	LoopbreakSignalled = 105

	class EM < com.rubyeventmachine.EmReactor
		def eventCallback a1, a2, a3
			s = String.from_java_bytes(a3.array[a3.position...a3.limit])
			EventMachine::event_callback a1, a2, s
		end
	end
	def self.initialize_event_machine
		@em = EM.new
	end
	def self.release_machine
		@em = nil
	end
	def self.add_oneshot_timer interval
		@em.installOneshotTimer interval
	end
	def self.run_machine
		@em.run
	end
	def self.stop
		@em.stop
	end
	def self.start_tcp_server server, port
		@em.startTcpServer server, port
	end
	def self.stop_tcp_server sig
		@em.stopTcpServer sig
	end
	def self.send_data sig, data, length
		@em.sendData sig, data, length
	end
	def self.send_datagram sig, data, length, address, port
		@em.sendDatagram sig, data, length, address, port
	end
	def self.connect_server server, port
		@em.connectTcpServer server, port
	end
	def self.close_connection sig, after_writing
		@em.closeConnection sig, after_writing
	end
	def self.start_tls sig
		@em.startTls sig
	end
	def self.signal_loopbreak
		@em.signalLoopbreak
	end
	def self.set_timer_quantum q
		@em.setTimerQuantum q
	end
	def self.epoll
		# Epoll is a no-op for Java.
		# The latest Java versions run epoll when possible in NIO.
	end
	def self.set_rlimit_nofile n_descriptors
		# Currently a no-op for Java.
	end
	def self.open_udp_socket server, port
		@em.openUdpSocket server, port
	end
	def self.library_type
		:java
	end
end

