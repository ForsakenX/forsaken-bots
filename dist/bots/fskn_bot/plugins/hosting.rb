# scan channel users for hosting
class Hosting < Meth::Plugin

  include DirectPlay

  def initialize *args
    super *args
    @bot.command_manager.register("hosting",self)
  end

  def help m
    "hosting => Scan channel users to see if anyone is hosting..."
  end

  def command m

    if m.personal
      m.reply "This command only works in a channel..."
      return
    end

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

    # have resulsts ?
    return unless users.length > 0

    m.reply "One moment please..."

    # check the users
    find_hosts(users){|results|

      # format hosts output
      hosts_output = []
      results[:hosts].each do |user|
        hosts_output << "#{user.nick}@#{user.ip}"
      end

      # print results
      m.reply "#{users.length} users were scanned "+
               "in #{results[:time_finished]-results[:time_started]} seconds. "+
               "#{hosts_output.length} where hosting: #{hosts_output.join(', ')}"

      # add hosts to game list
      results[:hosts].each do |user|
        next if GameModel.find(user.ip)
        game = GameModel.create({:user => user})
      end

    }

  end

end

