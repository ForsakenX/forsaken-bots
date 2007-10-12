require "#{DIST}/lib/direct_play.rb"
class GameModel

  #
  # Instance
  #

  include DirectPlay

  attr_accessor :replyto, :user, :client, :hosting#,
#                :timer, :start_time

  def initialize game
    @replyto     = game[:replyto]
    @user        = game[:user]
    @client      = game[:client]
    @hosting     = false
#    watch
  end

  def update game
    game.each do |prop,val|
      instance_variable_set(prop.to_s.gsub(/^/,'@').to_sym, val)
    end
  end

=begin
  def started
    @hosting     = true
    @start_time  = Time.now
    @bot.nickchg("_#{@games.length}_fskn_games")
    @bot.say @replyto, "#{hostmask} has started a game! "
  end

  def stopped
    destroy
    @bot.say @replyto, "#{hostmask} has stopped hosting..."
    @bot.nickchg("_#{@games.length}_fskn_games")
  end

  def watch
    @start_time = nil
    @timer = nil
    @timer = @bot.timer.add(5){
      hosting = hosting? @user.ip
      if hosting
        started unless @hosting
      else
        stopped if @hosting
      end
    }
  end
=end

  def hostmask
    "#{@user.nick}@#{@user.ip}"
  end

  def name
    @user.nick.downcase
  end

  def destroy
    @games.delete(self)
  end

  #
  # Class Tools
  #

  @@games = []

  def self.create game
game[:client].say "#tester", @@games
    unless g = find_by_name(game[:user].nick)
game[:client].say "#tester", @@games
      g = new(game)
      @@games << g
game[:client].say "#tester", @@games
    end
game[:client].say "#tester", @@games
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
    !@@games.detect{|game|game.name.downcase==name.downcase}.nil?
  end

end


class Game < Meth::Plugin

  def privmsg m
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
                                  :client  => m.client})
        m.reply "Game created @ #{game.hostmask}"
      end
    end
    game
  end

  # remove a game
  def unhost m
    user = m.source
    unless game = GameModel.find(user.nick)
      m.reply "You are not hosting..."
      return
    end
    game.destroy
    m.reply "Your game '#{game.hostmask}' has been removed..."
  end

end

