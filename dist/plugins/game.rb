
# Game Model
class Game

  #
  # Instance
  #

  include DirectPlay

  attr_accessor :replyto, :user, :bot, :hosting, :timer, :start_time

  def initialize settings
    @replyto     = settings[:replyto]
    @games       = settings[:games]
    @user        = settings[:user]
    @bot         = settings[:bot]
    @hosting     = false
    @start_time  = nil
    @timer       = nil
    watch
  end

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
    @timer = @bot.timer.add(5){
      hosting = hosting? @user.ip
      if hosting
        started unless @hosting
      else
        stopped if @hosting
      end
    }
  end

  def hostmask
    "#{@user.nick}@#{@user.ip}"
  end

  def name
    @user.nick.downcase
  end

  def destroy
    cleanup
    @games.delete(self)
  end

  #
  # Class Tools
  #

  @@games = []



end


class GamePlugin < Plugin

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
    games = Game.find_all
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
    games = Game.find_all
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
    user = m.source
    unless game = Game.find(user)
      m.reply "You already have a game up!"
    else
      game = Game.create(user)
    end
    game
  end

  # remove a game
  def unhost m
    user = m.source
    unless game = Game.find(user.nick)
      m.reply "#{game.hostmask} is not hosting..."
      return
    end
    game.destroy
    m.reply "#{game.hostmask} has been removed..."
  end

end

