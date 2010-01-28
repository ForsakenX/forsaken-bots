module DirectPlay

  # scan single user
  def self.hosting?(ip,&block)
    h = EM::Protocols::TcpConnectTester.test( ip, 47624 )
    h.callback {|time| block.call(true,time) }
    h.errback  {|time| block.call(false,time) }
  rescue Exception
    puts_error __FILE__,__LINE__
  end
 
  # scan list of users 
  def self.find_hosts(users,&finished)
    results = {
      :time_started         => Time.now,
      :time_finished        => nil,
      :hosts                => [],
    }
    # how many tests are we performing?
    tests = users.length
    # Run this after your done iwth a user
    finished_with_user = Proc.new {
      # where done with this  user
      tests -= 1;
      # are we completely done ?
      if tests == 0
        # finish time
        results[:time_finished] = Time.now
        # if were doen with all users then quit
        finished.call(results)
      end
    }
    # test each user
    users.each do |user|
      # scan host port
      h = EM::Protocols::TcpConnectTester.test( user.ip, 47624 )
      # lower timeout value
      h.timeout(1)
      # if succesfull
      h.callback {|*time|
        # we results[:hosts] a user
        results[:hosts] << user
        # were done with this user
        finished_with_user.call()
      }
      # if no connection
      h.errback {|*time| finished_with_user.call() }
    end
  rescue Exception
    puts_error __FILE__,__LINE__
  end

end
