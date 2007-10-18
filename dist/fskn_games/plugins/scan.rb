# scan channel users for hosting/playing
class Scan < Meth::Plugin

  include DirectPlay

  def help m
    "scan => Scans channel users to see if anyone is hosting or playing..."
  end

  def command m

    if m.personal?
      m.reply "This command only works in a channel..."
      return
    end

    m.reply "One moment please..."

    # user globs
    patterns = m.params

    # list of users
    users = m.channel.users

    # remove bots from list
    Irc::Client.clients.each do |name,client|
      users.each do |user|
        users.delete(user) if user.nick == client.nick
      end
    end

    # compact by unique ip addresses
    users.each do |user|
      users.each do |u|
        users.delete(user) if (user != u) && (user.ip == u.ip)
      end
    end

    # filter users against patterns
    users = Irc::User.filter(users,patterns)

    # check the users
    check(users){|results|

      # format hosts output
      hosts_output = []
      results[:hosts].each do |user|
        hosts_output << "#{user.nick}@#{user.ip}"
      end

      # format player output
      players_output = []
      results[:players].each do |user|
        players_output << "#{user.nick}@#{user.ip}"
      end

      # print results
      m.reply "Scanned #{results[:total_ports_scanned]} ports "+
               "in #{results[:time_finished]-results[:time_started]} seconds... "+
               "#{users.length} users were scanned... "+
               "( #{players_output.length} playing: "+
               "#{players_output.join(', ')} ) "+
               "( #{hosts_output.length} hosting: "+
               "#{hosts_output.join(', ')} ) "

      # add hosts to game list
      results[:hosts].each do |user|
        next if GameModel.find(m.source.ip)
        game = GameModel.create({:user => m.source})
      end

    }

  end

end

