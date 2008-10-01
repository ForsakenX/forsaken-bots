require "rexml/document"
class GameModel

  include DirectPlay

  #
  # Class Tools
  #

  @@games = []
  @@event = Event.new
  @@wait_timeout = 5*60

  def self.wait_timeout; @@wait_timeout; end
  def self.games; @@games; end
  def self.event; @@event; end

  def self.create game
    if g = find(game[:ip])
      g.version = version
    else
      g = new(game)
      @@games << g
    end
    g
  end

  def self.find(ip)
    @@games.detect{|game|game.ip==ip}
  end

  def self.update_xml
    doc = REXML::Document.new
    games = doc.add_element("games")
    @@games.each do |game|
      time = game.start_time.strftime("%a, %d %b %Y %H:%M:%S GMT-0400") if game.start_time
      games.add_element("game",{ "nick" => game.name,
                                 "ip"   => game.ip,
                                 "version" => game.version,
                                 "started_at" => time})
    end
    path = File.expand_path("#{ROOT}/db/games.xml")
    file = File.open( path, 'w+' )
    file.write doc
    file.close
  end

  #
  # Instance
  #

  # reader/writers
  attr_reader :replyto, :user, :bot, :hosting, :timer, :start_time, :version, :created_at

  def initialize game
    @version     = game[:version]
    @canceled    = false
    @user        = game[:user]
    @hosting     = false
    @created_at  = Time.now
    @start_time  = nil
    @fail_count  = 0
    @running     = false
    @timer       = EM::PeriodicTimer.new( 1 ) { # try every 1 second
      #puts "GameTimer (#{hostmask}): Status: Starting"
      # if were cancled dont run lagging timers
      if @canceled
        #puts "GameTimer (#{hostmask}): Stopped: Allready canceled"
        next
      end
      # dont run more than one timer at a time
      if @running
        #puts "GameTimer (#{hostmask}): Stopped: Allready running."
        next
      end
      @running = true
      hosting?(
        @user.ip,
        # the port is open
        Proc.new{|time|
          #puts "GameTimer (#{hostmask}): Status: Port Open"
          @fail_count = 0
          @timer.interval = 30 # put interval back at 30 for open port
          # we are allready hosting
          if @hosting
            #puts "GameTimer (#{hostmask}): Status: Allready Hosting"
            @running = false
            next
          end
          #puts "GameTimer (#{hostmask}): Status: Started Hosting"
          # create the game
          @hosting     = true
          @start_time  = Time.now
          @timer.interval = 30
          @@event.call("game.started",self)
          GameModel.update_xml
          @running = false
          #puts "GameTimer (#{hostmask}): Status: Finished Running"
        },
        # the port is closed
        Proc.new{|time|
          #puts "GameTimer (#{hostmask}): Status: Port Closed"
          # is the game up yet ?
          # or did it just finish ?
          if @hosting
            # give them a few chances to have non responsive ports
            #puts "GameTimer (#{hostmask}): Status: Fail Count == #{@fail_count}"
            if @fail_count < 5
              @timer.interval = 1 # lower interval count to catch a closed game
              @fail_count += 1
              @running = false
              next
            # chances up
            else
              # game just finished close shop
              #puts "GameTimer (#{hostmask}): Status: Closing Game"
              destroy
            end
          # the game hasn't started yet
          else
            #puts "GameTimer (#{hostmask}): Status: Not started yet"
            seconds = (Time.now - @created_at).to_i
            if seconds > (GameModel.wait_timeout)
              #puts "GameTimer (#{hostmask}): Status: Closed: To long to start"
              destroy
              @@event.call('game.time.out',self)
            end
          end
          #puts "GameTimer (#{hostmask}): Status: Finished running"
          @running = false
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
    @canceled = true
    @timer.cancel if @timer
    @@games.delete(self)
    if @hosting
      @hosting = false
      @@event.call("game.finished",self)
      GameModel.update_xml
    end
  end

end
