class IrcCommandManager
  def self.scan

    ## only valid in channels
    return if @msg.private

    ## list of users
    users = IrcUser.users.select{|u| u.ip}

    ## compact by unique ip addresses
    users.each do |user|
      users.each do |u|
        users.delete(user) if (user != u) && (user.ip == u.ip)
      end
    end

    ## tempt message
    @msg.reply "One moment please..."

    # check the users
    DirectPlay::find_hosts(users){|results|

      # format hosts output
      hosts = []
      results[:hosts].each do |user|
        hosts << "#{user.nick}@#{user.ip}"
      end

      # calculations
      time_taken = results[:time_finished] - results[:time_started]

      # print results
      @msg.reply "Scanned (#{users.length}) users (#{time_taken}) seconds. "+
                 "Found (#{hosts.length}) hosting: #{hosts.join(', ')}"

=begin
      # add hosts to game list
      results[:hosts].each do |user|
        next if GameModel.find(user.ip)
        game = GameModel.create({:user => user})
      end
=end

    }

  end
end

