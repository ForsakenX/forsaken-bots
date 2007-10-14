require "#{DIST}/lib/direct_play.rb"
class GameModel

  include DirectPlay

  #
  # Class Tools
  #

  @@games = []

  def self.create game
    unless g = find_by_name(game[:user].nick)
      g = new(game)
      @@games << g
    end
    g
  end

  def self.find(target)
    return find_all if target == :all
    return find_by_name(target)
  end

  def self.find_all
    @@games
  end

  def self.find_by_name(name)
    @@games.detect{|game|game.name.downcase==name.downcase}
  end

  #
  # Instance Accessors
  #

  attr_accessor :replyto, :user, :bot, :hosting, :timer, :start_time

  def hostmask
    "#{@user.nick}@#{@user.ip}"
  end

  def name
    @user.nick.downcase
  end

  #
  # Instance
  #

  def initialize game
    @replyto     = game[:replyto]
    @user        = game[:user]
    @bot         = game[:bot]
    @hosting     = false
    @start_time  = nil
    @timer       = EM::add_periodic_timer( 5 ) {
      puts "GameTimer Called"
      hosting?(
        @user.ip,
        # game started
        Proc.new{|time|
          next if @hosting
          @hosting     = true
          @start_time  = Time.now
          @bot.send_nick("_#{@@games.length}_fskn_games")
          @bot.say @replyto, "#{hostmask} has started a game! "
        },
        # game finished
        Proc.new{|time|
          next unless @hosting
          destroy
        })
    }
    puts @timer.inspect
  end

  def destroy
    EM::cancel_timer(@timer) if @timer
    @@games.delete(self)
    if @hosting
      @hosting = false
      @bot.say @replyto, "#{hostmask} has stopped hosting..."
      @bot.send_nick("_#{@@games.length}_fskn_games")
    end
  end

end


class Game < Meth::Plugin

  include DirectPlay

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
        "game scan [[pattern]...] => Queries a user to see if they are hosting/playing. "+
        "[[pattern]...] patterns seperated by a space to search for user names."
      else
        "game [command] => game tools.  "+
        "[command] can be one of host, unhost, list, status"
    end
  end

  # get status of running games
  def status m
    games = GameModel.find_all
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
    games = GameModel.find_all
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
    if game = GameModel.find(m.source.nick)
      m.reply "You already have a game up!"
    else
      if game = GameModel.create({:replyto => m.replyto,
                                  :user    => m.source,
                                  :bot     => @bot})
        m.reply "Game created @ #{game.hostmask}"
      end
    end
    game
  end

  # remove a game
  def unhost m
    user = m.source
    unless game = GameModel.find(user.nick)
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
    users = m.channel.nil? ? [m.source] : @bot.users
    # filter list against params
    users = Irc::User.filter(targets)
    # remove bot from list
    users.delete(users.detect{|u| u.nick == @bot.nick})
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
        next if GameModel.find(m.source.nick)
        game = GameModel.create({:replyto => m.replyto,
                                 :user    => m.source,
                                 :bot     => @bot})
      end
    }
  end

end

