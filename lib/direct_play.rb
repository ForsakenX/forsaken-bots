#!/usr/bin/ruby

require 'rubygems'
require 'eventmachine'

module DirectPlay

  def hosting? ip
    result = false
    EM.epoll
    EM.run {
      h = EM::Protocols::TcpConnectTester.test( ip, 47624 )
      h.callback {|time|
        result = true
        EM.stop
      }
      h.errback {|time|
        EM.stop
      }
    }
    result
  end

  def check users
    results = {
      :total_ports_scanned  => 0,
      :time_started         => Time.now,
      :time_finished        => nil,
      :hosts                => [],
      :players              => []
    }
    # how many tests are we performing?
    tests = users.length
    # run em
    EM.epoll
    EM.run { 
      # Run this after your done iwth a user
      finished_with_user = Proc.new {
        # where done with this  user
        tests -= 1;
        # if were doen with all users then quit
        EM.stop if tests == 0
      }
      # test each user
      users.each do |user|
        # scan host port
        h = EM::Protocols::TcpConnectTester.test( user.host, 47624 )
        # scanned port
        results[:total_ports_scanned] += 1
        # if succesfull
        h.callback {|time|
          # we results[:hosts] a user
          results[:hosts] << user
          # were done with this user
          finished_with_user.call()
          # skip checking for player ports open
          next
        }
        # if no connection
        h.errback {|time|
          # ports to check
          ports = 101
          # check if user is playing
          (2300..2400).each {|i|
            # scan a player port
            p = EM::Protocols::TcpConnectTester.test( user.host, i )
            # scanned port
            results[:total_ports_scanned] += 1
            # player port is open
            p.callback {|time|
              # we found a player !
              results[:players] << user
              # down the count
              ports -= 1;
              # debuggin print port number
              # port = (2400-(101-ports))
              # if were done now
              finished_with_user.call() if ports == 0
            }
            # player port is not open
            p.errback {|time|
              # down the count
              ports -= 1;
              # if were done now
              finished_with_user.call() if ports == 0
            }
          }
        }
      end
    }
    results[:time_finished] = Time.now
    results
  end
end
