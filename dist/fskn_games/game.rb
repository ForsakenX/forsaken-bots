class Game < Meth::Plugin

  include DirectPlay

  def initialize *args
    super *args
    GameModel.event.register("game.started",Proc.new{|game|
      nick = @bot.nick.gsub(/^_[0-9]*_/,"_#{GameModel.games.length}_")
      @bot.send_nick(nick)
      @bot.channels.each do |name,channel|
        @bot.say name, "#{game.hostmask} has started a game!"
      end
    })
    GameModel.event.register("game.finished",Proc.new{|game|
      nick = @bot.nick.gsub(/^_[0-9]*_/,"_#{GameModel.games.length}_")
      @bot.send_nick(nick)
      @bot.channels.each do |name,channel|
        @bot.say name, "#{game.hostmask} has stopped hosting..."
      end
    })
  end

  def command m
    case m.params.shift
    when "status"
      status m
    when "list"
      list m
    when "host"
      host m
    when "unhost"
      unhost m
    when "scan"
      scan m
    else #when /help/,"",nil
      m.reply help(m)
    end
  end

  def help m
    case m.params.shift
      when "host"
        "game host => Creats a game.  "+
        "Queries you continously until you have a game up.  "+
        "At which time this chat will be notified. "+
        "When you are no longer hosting, "+
        "I will remove the game and notify the chat"
      when "unhost"
        "game unhost => Closes your game..."
      when "status"
        "game status => Print status on running games..."
      when "list"
        "game list => Prints list of games..."
      when "scan"
        "game scan => Scans for users hosting in channel..."
      else
        "game [command] => game tools.  "+
        "[command] can be one of host, unhost, list, status, scan"
    end
  end

  # get status of running games
  def status m
    games = GameModel.games
    unless games.length > 0
      m.reply "There are currently no games..."
      return
    end
    hosts = []
    games.each { |game|
      next unless game.hosting
      seconds = (Time.now - game.start_time).to_i
      minutes = seconds / 60; seconds = seconds % 60
      hours   = minutes / 60; minutes = minutes % 60
      host = []
      host << game.hostmask + " has been playing for " 
      host << "#{hours} hours " if hours
      host << "#{minutes} minutes " if minutes
      host << "#{seconds} seconds " if seconds
      hosts << "( #{host} )"
    }
    m.reply "There are #{hosts.length} games up: #{hosts.join(', ')}"
  end

  # list games
  def list m
    games = GameModel.games
    unless games.length > 0
      m.reply "There are currently no games..."
      return
    end
    hostmasks = []
    games.each do |game|
      hostmasks << game.hostmask
    end
    m.reply hostmasks.join(', ')
  end

  # start a game
  def host m
    if game = GameModel.find(m.source.ip)
      m.reply "You already have a game up!"
    else
      if game = GameModel.create({:user => m.source})
        m.reply "Game created @ #{game.hostmask}"
      end
    end
    game
  end

  # remove a game
  def unhost m
    user = m.source
    unless game = GameModel.find(user.ip)
      m.reply "Your not hosting..."
      return
    end
    game.destroy
    m.reply "Your game has been removed..."
  end

  # find hosts
  def scan m
    m.reply "One moment please..."
    # parse input
    targets = m.params
    # list of users
    users = m.channel.nil? ? [m.source] : m.channel.users
    # remove bots from list
    Irc::Client.clients.each do |name,client|
      users.delete(users.detect{|u| u.nick == client.nick})
    end
    # limit by ip
    users.each do |user|
      users.delete(users.detect{|u| u != user && u.ip == user.ip })
    end
    # filter list against params
    users = Irc::User.filter(users,targets)
    # check the users
    check(users){|results|
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
      # add hosts to watched game list
      results[:hosts].each do |user|
        next if GameModel.find(m.source.ip)
        game = GameModel.create({:user => m.source})
      end
    }
  end

end

