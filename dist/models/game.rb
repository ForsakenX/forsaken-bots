class GameModel

  include DirectPlay

  #
  # Class Tools
  #

  @@games = []
  @@event = Meth::Event.new($logger)

  def self.games; @@games; end
  def self.event; @@event; end

  def self.create game
    unless g = find(game[:ip])
      g = new(game)
      @@games << g
    end
    g
  end

  def self.find(ip)
    @@games.detect{|game|game.ip==ip}
  end

  #
  # Instance
  #

  # reader/writers
  attr_reader :replyto, :user, :bot, :hosting, :timer, :start_time

  def initialize game
    @user        = game[:user]
    @hosting     = false
    @start_time  = nil
    @timer       = EM::PeriodicTimer.new( 1 ) { # try every 1 second
      puts "GameTimer Called"
      hosting?(
        @user.ip,
        # game started
        Proc.new{|time|
          next if @hosting
          @hosting     = true
          @start_time  = Time.now
          @timer.interval = 20 # only connect after 20 seconds
          @@event.call("game.started",self)
        },
        # game finished
        Proc.new{|time|
          next unless @hosting
          destroy
        })
    }
  end

  #
  # Instance Helpers
  #

  def hostmask
    "#{@user.nick}@#{@user.ip}"
  end

  def name
    @user.nick.downcase
  end

  def ip
    @user.ip
  end

  #
  # Instance Methods
  #

  def destroy
    @timer.cancel if @timer
    @@games.delete(self)
    if @hosting
      @hosting = false
      @@event.call("game.finished",self)
    end
  end

end
