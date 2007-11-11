# $Id: pr_eventmachine.rb 319 2007-05-22 22:11:18Z blackhedd $
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
#-------------------------------------------------------------------
#
# 

# TODO List:
# TCP-connects currently assume non-blocking connect is available- need to
#  degrade automatically on versions of Ruby prior to June 2006.
#

require 'singleton'
require 'forwardable'
require 'socket'
require 'fcntl'


module EventMachine


  class << self
    # This is mostly useful for automated tests.
    # Return a distinctive symbol so the caller knows whether he's dealing
    # with an extension or with a pure-Ruby library.
    def library_type
      :pure_ruby
    end

    # #initialize_event_machine
    def initialize_event_machine
      Reactor.instance.initialize_for_run
    end

    # #add_oneshot_timer
    #--
    # Changed 04Oct06: intervals from the caller are now in milliseconds, but our native-ruby
    # processor still wants them in seconds.
    def add_oneshot_timer interval
      Reactor.instance.install_oneshot_timer(interval / 1000)
    end

    # run_machine
    def run_machine
      Reactor.instance.run
    end

    # release_machine. Probably a no-op.
    def release_machine
    end

    # #stop
    def stop
      Reactor.instance.stop
    end

    # #connect_server. Return a connection descriptor to the caller.
    # TODO, what do we return here if we can't connect?
    def connect_server host, port
      EvmaTCPClient.connect(host, port).uuid
    end

    # #send_data
    def send_data target, data, datalength
      selectable = Reactor.instance.get_selectable( target ) or raise "unknown send_data target"
      selectable.send_data data
    end

    # #close_connection
    # The extension version does NOT raise any kind of an error if an attempt is made
    # to close a non-existent connection. Not sure whether we should. For now, we'll
    # raise an error here in that case.
    def close_connection target, after_writing
      selectable = Reactor.instance.get_selectable( target ) or raise "unknown close_connection target"
      selectable.schedule_close after_writing
    end

    # #start_tcp_server
    def start_tcp_server host, port
      (s = EvmaTCPServer.start_server host, port) or raise "no acceptor"
      s.uuid
    end

    # #signal_loopbreak
    def signal_loopbreak
      Reactor.instance.signal_loopbreak
    end

    # #get_peername
    def get_peername sig
      selectable = Reactor.instance.get_selectable( sig ) or raise "unknown get_peername target"
      selectable.get_peername
    end

    # #open_udp_socket
    def open_udp_socket host, port
      EvmaUDPSocket.create(host, port).uuid
    end

    # #send_datagram. This is currently only for UDP!
    # We need to make it work with unix-domain sockets as well.
    def send_datagram target, data, datalength, host, port
      selectable = Reactor.instance.get_selectable( target ) or raise "unknown send_data target"
      selectable.send_datagram data, Socket::pack_sockaddr_in(port, host)
    end


    # #set_timer_quantum in milliseconds. The underlying Reactor function wants a (possibly
    # fractional) number of seconds.
    def set_timer_quantum interval
      Reactor.instance.set_timer_quantum(( 1.0 * interval) / 1000.0)
    end

  end

end


#-----------------------------------------------------------------

module EventMachine

  class Error < Exception; end

end

#-----------------------------------------------------------------

module EventMachine

  # Factored out so we can substitute other implementations
  # here if desired, such as the one in ActiveRBAC.
  module UuidGenerator

    def self.generate
      if @ix and @ix >= 10000
        @ix = nil
        @seed = nil
      end

      @seed ||= `uuidgen`.chomp.gsub(/-/,"")
      @ix ||= 0

      "#{@seed}#{@ix += 1}"
    end

  end

end

#-----------------------------------------------------------------

module EventMachine

  TimerFired = 100
	ConnectionData = 101
	ConnectionUnbound = 102
	ConnectionAccepted = 103
	ConnectionCompleted = 104
	LoopbreakSignalled = 105

end

#-----------------------------------------------------------------

module EventMachine
class Reactor
  include Singleton

  def initialize
    initialize_for_run
  end

  def install_oneshot_timer interval
    uuid = UuidGenerator::generate
    @timers << [Time.now + interval, uuid]
    @timers.sort! {|a,b| a.first <=> b.first}
    uuid
  end

  # Called before run, this is a good place to clear out arrays
  # with cruft that may be left over from a previous run.
  def initialize_for_run
    @running = false
    @stop_scheduled = false
    @selectables ||= {}; @selectables.clear
    @timers = []
    set_timer_quantum(0.5)
  end

  def add_selectable io
    @selectables[io.uuid] = io
  end

  def get_selectable uuid
    @selectables[uuid]
  end

  def run
    raise Error.new( "already running" ) if @running
    @running = true
    open_loopbreaker

    loop {
      break if @stop_scheduled
      run_timers
      break if @stop_scheduled
      crank_selectables
    }

    close_loopbreaker
    @selectables.each {|k, io| io.close}
    @selectables.clear

    @running = false
  end

  def run_timers
    now = Time.now
    while @timers.length > 0 and @timers.first.first <= now
      t = @timers.shift
      EventMachine::event_callback "", TimerFired, t.last
    end
  end

  def crank_selectables
      #$stderr.write 'R'

      readers = @selectables.values.select {|io| io.select_for_reading?}
      writers = @selectables.values.select {|io| io.select_for_writing?}

      s = select( readers, writers, nil, @timer_quantum)

      s and s[1] and s[1].each {|w| w.eventable_write }
      s and s[0] and s[0].each {|r| r.eventable_read }

      @selectables.delete_if {|k,io|
        if io.close_scheduled?
          io.close
          true
        end
      }
  end

  # #stop
  def stop
    raise Error.new( "not running") unless @running
    @stop_scheduled = true
  end

  def open_loopbreaker
    @loopbreak_writer.close if @loopbreak_writer
    rd,@loopbreak_writer = IO.pipe
    LoopbreakReader.new rd
  end

  def close_loopbreaker
    @loopbreak_writer.close
    @loopbreak_writer = nil
  end

  def signal_loopbreak
    @loopbreak_writer.write '+' if @loopbreak_writer
  end

  def set_timer_quantum interval_in_seconds
    @timer_quantum = interval_in_seconds
  end

end

end


#--------------------------------------------------------------

class IO
  extend Forwardable
  def_delegator :@my_selectable, :close_scheduled?
  def_delegator :@my_selectable, :select_for_reading?
  def_delegator :@my_selectable, :select_for_writing?
  def_delegator :@my_selectable, :eventable_read
  def_delegator :@my_selectable, :eventable_write
  def_delegator :@my_selectable, :uuid
  def_delegator :@my_selectable, :send_data
  def_delegator :@my_selectable, :schedule_close
  def_delegator :@my_selectable, :get_peername
  def_delegator :@my_selectable, :send_datagram
end

#--------------------------------------------------------------

module EventMachine
  class Selectable

    attr_reader :io, :uuid

    def initialize io
      @uuid = UuidGenerator.generate
      @io = io

      m = @io.fcntl(Fcntl::F_GETFL, 0)
      @io.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK | m)
      # TODO, should set CLOEXEC on Unix?

      @close_scheduled = false
      @close_requested = false

      se = self; @io.instance_eval { @my_selectable = se }
      Reactor.instance.add_selectable @io
    end

    def close_scheduled?
      @close_scheduled
    end

    def select_for_reading?
      false
    end

    def select_for_writing?
      false
    end

    def get_peername
      nil
    end

  end

end

#--------------------------------------------------------------


module EventMachine

  class StreamObject < Selectable
    def initialize io
      super io
      @outbound_q = []
    end

    # If we have to close, or a close-after-writing has been requested,
    # then don't read any more data.
    def select_for_reading?
      true unless (@close_scheduled || @close_requested)
    end

    # If we have to close, don't select for writing.
    # Otherwise, see if the protocol is ready to close.
    # If not, see if he has data to send.
    # If a close-after-writing has been requested and the outbound queue
    # is empty, convert the status to close_scheduled.
    def select_for_writing?
      unless @close_scheduled
        if @outbound_q.empty?
          @close_scheduled = true if @close_requested
          false
        else
          true
        end
      end
    end

    # Proper nonblocking I/O was added to Ruby 1.8.4 in May 2006.
    # If we have it, then we can read multiple times safely to improve
    # performance.
    # TODO, coalesce multiple reads into a single event.
    # TODO, do the function check somewhere else and cache it.
    def eventable_read
      begin
        if io.respond_to?(:read_nonblock)
          10.times {
            data = io.read_nonblock(4096)
            EventMachine::event_callback uuid, ConnectionData, data
          }
        else
          data = io.sysread(4096)
          EventMachine::event_callback uuid, ConnectionData, data
        end
      rescue Errno::EAGAIN
        # no-op
      rescue Errno::ECONNRESET, EOFError
        @close_scheduled = true
        EventMachine::event_callback uuid, ConnectionUnbound, nil
      end

    end

    # Provisional implementation. Will be re-implemented in subclasses.
    # TODO: Complete this implementation. As it stands, this only writes
    # a single packet per cycle. Highly inefficient, but required unless
    # we're running on a Ruby with proper nonblocking I/O (Ruby 1.8.4
    # built from sources from May 25, 2006 or newer).
    # We need to improve the loop so it writes multiple times, however
    # not more than a certain number of bytes per cycle, otherwise
    # one busy connection could hog output buffers and slow down other
    # connections. Also we should coalesce small writes.
    # URGENT TODO: Coalesce small writes. They are a performance killer.
    def eventable_write
      # coalesce the outbound array here, perhaps
      while data = @outbound_q.shift do
        begin
          data = data.to_s
          w = if io.respond_to?(:write_nonblock)
            io.write_nonblock data
          else
            io.syswrite data
          end

          if w < data.length
            $outbound_q.unshift data[w..-1]
            break
          end
        rescue Errno::EAGAIN
          @outbound_q.unshift data
        rescue EOFError, Errno::ECONNRESET
          @close_scheduled = true
          @outbound_q.clear
        end
      end

    end

    # #send_data
    def send_data data
      # TODO, coalesce here perhaps by being smarter about appending to @outbound_q.last?
      unless @close_scheduled or @close_requested or !data or data.length <= 0
        @outbound_q << data.to_s
      end
    end

    # #schedule_close
    # The application wants to close the connection.
    def schedule_close after_writing
      if after_writing
        @close_requested = true
      else
        @close_scheduled = true
      end
    end

    # #get_peername
    # This is defined in the normal way on connected stream objects.
    # Return an object that is suitable for passing to Socket#unpack_sockaddr_in or variants.
    # We could also use a convenience method that did the unpacking automatically.
    def get_peername
      io.getpeername
    end

  end


end


#--------------------------------------------------------------



module EventMachine
  class EvmaTCPClient < StreamObject

    def self.connect host, port
      sd = Socket.new( Socket::AF_INET, Socket::SOCK_STREAM, 0 )
      begin
        # TODO, this assumes a current Ruby snapshot.
        # We need to degrade to a nonblocking connect otherwise.
        sd.connect_nonblock( Socket.pack_sockaddr_in( port, host ))
      rescue Errno::EINPROGRESS
      end
      EvmaTCPClient.new sd
    end


    def initialize io
      super
      @pending = true
    end


    def select_for_writing?
      @pending ? true : super
    end

    def select_for_reading?
      @pending ? false : super
    end

    def eventable_write
      if @pending
        @pending = false
        EventMachine::event_callback uuid, ConnectionCompleted, ""
      else
        super
      end
    end



  end
end


#--------------------------------------------------------------

module EventMachine
  class EvmaTCPServer < Selectable

    class << self
      # Versions of ruby 1.8.4 later than May 26 2006 will work properly
      # with an object of type TCPServer. Prior versions won't so we
      # play it safe and just build a socket.
      #
      def start_server host, port
        sd = Socket.new( Socket::AF_INET, Socket::SOCK_STREAM, 0 )
        sd.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true )
        sd.bind( Socket.pack_sockaddr_in( port, host ))
        sd.listen( 50 ) # 5 is what you see in all the books. Ain't enough.
        EvmaTCPServer.new sd
      end
    end

    def initialize io
      super io
    end


    def select_for_reading?
      true
    end

    #--
    # accept_nonblock returns an array consisting of the accepted
    # socket and a sockaddr_in which names the peer.
    # Don't accept more than 10 at a time.
    def eventable_read
      begin
        10.times {
          descriptor,peername = io.accept_nonblock
          sd = StreamObject.new descriptor
          EventMachine::event_callback uuid, ConnectionAccepted, sd.uuid
        }
      rescue Errno::EWOULDBLOCK, Errno::EAGAIN
      end
    end


  end
end



#--------------------------------------------------------------

module EventMachine
  class LoopbreakReader < Selectable

    def select_for_reading?
      true
    end

    def eventable_read
          io.sysread(128)
          EventMachine::event_callback "", LoopbreakSignalled, ""
    end

  end
end

#--------------------------------------------------------------


module EventMachine

  class DatagramObject < Selectable
    def initialize io
      super io
      @outbound_q = []
    end

    # #send_datagram
    def send_datagram data, target
      # TODO, coalesce here perhaps by being smarter about appending to @outbound_q.last?
      unless @close_scheduled or @close_requested
        @outbound_q << [data.to_s, target]
      end
    end

    # #select_for_writing?
    def select_for_writing?
      unless @close_scheduled
        if @outbound_q.empty?
          @close_scheduled = true if @close_requested
          false
        else
          true
        end
      end
    end

    # #select_for_reading?
    def select_for_reading?
      true
    end


  end


end


#--------------------------------------------------------------

module EventMachine
  class EvmaUDPSocket < DatagramObject

    class << self
      def create host, port
        sd = Socket.new( Socket::AF_INET, Socket::SOCK_DGRAM, 0 )
        sd.bind Socket::pack_sockaddr_in( port, host )
        EvmaUDPSocket.new sd
      end
    end

    # #eventable_write
    # This really belongs in DatagramObject, but there is some UDP-specific stuff.
    def eventable_write
      40.times {
        break if @outbound_q.empty?
        begin
          data,target = @outbound_q.first

          # This damn better be nonblocking.
          io.send data.to_s, 0, target

          @outbound_q.shift
        rescue Errno::EAGAIN
          # It's not been observed in testing that we ever get here.
          # True to the definition, packets will be accepted and quietly dropped
          # if the system is under pressure.
          break
        rescue EOFError, Errno::ECONNRESET
          @close_scheduled = true
          @outbound_q.clear
        end
      }
    end

    # Proper nonblocking I/O was added to Ruby 1.8.4 in May 2006.
    # If we have it, then we can read multiple times safely to improve
    # performance.
    def eventable_read
      begin
        if io.respond_to?(:recvfrom_nonblock)
          40.times {
            data,@return_address = io.recvfrom_nonblock(16384)
            EventMachine::event_callback uuid, ConnectionData, data
            @return_address = nil
          }
        else
          raise "unimplemented datagram-read operation on this Ruby"
        end
      rescue Errno::EAGAIN
        # no-op
      rescue Errno::ECONNRESET, EOFError
        @close_scheduled = true
        EventMachine::event_callback uuid, ConnectionUnbound, nil
      end

    end


    def send_data data
      send_datagram data, @return_address
    end

  end
end

#--------------------------------------------------------------


