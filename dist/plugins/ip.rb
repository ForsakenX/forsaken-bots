require "#{DIST}/lib/direct_play"
class Ip

  include DirectPlay

  def privmsg m
    # test topic
    case m.params.shift
    when "list"
      list m
    when "hosting"
      is_hosting? m
    when "scan"
      scan m
    else # default help
      m.reply help(m)
    end
  end

  def help m
    case m.params.shift
      when "list"
        "ip list [[pattern]...] => Gets a user[s] ip address. "+
        "(optional) [[pattern]..] patterns seperated by space to search for user names. "+
        "Leave blank to get all addresses."
      when "scan"
        "ip scan [[pattern]...] => Queries a user to see if they are hosting/playing. "+
        "[[pattern]...] patterns seperated by a space to search for user names."
      when "hosting"
        "ip hosting <ip> => Check if an ip is hosting..."
      else
        "ip [command] => ip address tools. "+
        "[command] can be one of: list, scan, hosting"
    end
  end

  def is_hosting? m
    ip = m.params.shift
    if hosting? ip
      m.reply "#{ip} is hosting..."
    else
      m.reply "#{ip} is NOT hosting..."
    end
  end

  # find hosts
  def scan m
    m.reply "One moment please..."
    # parse input
    targets = m.params
    # list of users
    users = m.channel.nil? ? [m.source] : m.client.users
    # filter list against params
    users = m.client.users.filter targets
    # check the users
    results = check(users)
    # format output
    hosts_output = []
    results[:hosts].each do |user|
      hosts_output << "#{user.nick}@#{user.ip}"
    end
    players_output = []
    results[:players].each do |user|
      players_output << "#{user.nick}@#{user.ip}"
    end
    m.reply "Scanned #{results[:total_ports_scanned]} ports "+
             "in #{results[:time_finished]-results[:time_started]} seconds... "+
             "#{users.length} users were scanned... "+
             "( #{players_output.length} playing: "+
             "#{players_output.join(', ')} ) "+
             "( #{hosts_output.length} hosting: "+
             "#{hosts_output.join(', ')} ) "
    # add hosts to game list
    results[:hosts].each do |user|
      @bot.plugins['game'].create(m,user)
    end
  end

  # get ip of user
  def list m

    #
    targets = m.params

    # output holder
    list = []

    # get and format list of found addresses
    m.client.users.filter(targets).each do |user|
      list << "#{user.nick} => #{user.ip}"
    end

    list = list.join(', ')

    # send the answer
    m.reply "A list has been messaged to you..." if m.channel
    
    # pm to user
    m.reply_directly list

  end

end

