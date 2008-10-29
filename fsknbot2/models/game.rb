require "rexml/document"

#
# Startup
#

# periodic game scanner
$run_observers << Proc.new(){ EM::PeriodicTimer.new(30){ ScanCommand.run } }

# initial topic checker
#EM::Timer.new(10){ Game.update }


#
# Public API
#

class Game
  class << self

    @@games = []; def games; @@games; end

    def create game
      if g = Game.find(game[:host].ip)
        g.version = game[:version]
      else
        g = Game.new(game)
        @@games << g
      end
      g
    end

    def destroy ip
      if game = Game.find(ip)
        game.destroy
      end
      game
    end

    def find ip
      @@games.detect{|game|game.ip==ip}
    end

    def length
      @@games.length
    end

    def update
      update_topic
      update_xml
    end

    def update_topic
      games = @@games.select{|g|g.hosting}.length
      current = IrcTopic.get.split('games')[0].to_i
      if current != games
        topic = IrcTopic.get.sub(/^[0-9]+/,games.to_s)
        IrcConnection.topic topic
      end
    end

    def update_xml
      doc = REXML::Document.new
      games = doc.add_element("games")
      @@games.each do |game|
        time = game.start_time.strftime("%a, %d %b %Y %H:%M:%S GMT-0400") if game.start_time
        games.add_element("game",{ "nick" => game.name,
                                   "ip"   => game.ip,
                                   "version" => game.version,
                                   "started_at" => time})
      end
      begin
  	file = File.open( File.expand_path( "#{ROOT}/db/games.xml" ), 'w+' )
  	file.write doc
  	file.close
      rescue Exception
      	puts "Error Saving Games.xml: #{$!}"
      end
    end

  end
end

#
# Instance
#

class Game

  attr_reader :host, :hosting, :timer, :start_time, :created_at, :ip, :timeout
  attr_accessor :version

  def initialize game
    @timeout     = 5 * 60
    @version     = game[:version]
    @host        = game[:host]
    @ip          = @host.ip
    @canceled    = false
    @hosting     = false
    @checking     = false
    @start_time  = nil
    @fail_count  = 0
    @created_at  = Time.now
    @timer       = EM::PeriodicTimer.new( 1 ) { check_game }
  end

  def name
    @host.nick
  end

  def hostmask
    "#{name}@#{@ip}"
  end

  def check_game
    status "Checking Game"
    if @canceled || @checking
      return status("Stopped: canceled (#{@canceled}) checking (#{@checking})")
    end
    @checking = true
    DirectPlay::hosting?( @host.ip ) do |hosting,time|
      hosting ? port_open : port_closed
      @checking = false
    end
  end

  def port_open
    status "Port Open"
    @fail_count = 0
    @hosting ? game_already_started : started_hosting
  end

  def port_closed
    status "Port Closed"
    @fail_count += 1
    @hosting ? stopped_hosting : game_not_started
  end

  def started_hosting
    status "Started Hosting"
    @hosting     = true
    @start_time  = Time.now
    @timer.interval = 30  # higher updater
    IrcConnection.chatmsg "#{hostmask} has started a game!"
    Game.update
  end

  def stopped_hosting
    if @fail_count < 5
      status "Fail Count (#{@fail_count})"
      @timer.interval = 1 # lower check interval to retest quickly
      return
    end
    status "Closing: Finished"
    IrcConnection.chatmsg "Game Finished!"
    @hosting = false
    destroy
  end

  def game_already_started
    status "Allready Hosting"
    @timer.interval = 30 
  end

  def game_not_started
    status "Not started yet"
    seconds = (Time.now - @created_at).to_i
    if seconds > @timeout
      status "Closing: To long to start"
      IrcConnection.chatmsg "Game Timeout!"
      destroy
    end
  end

  def destroy
    @@games.delete(self)
    @canceled = true
    @timer.cancel if @timer
    Game.update
  end

  def status msg
    #puts "GameTimer (#{hostmask}): #{msg}"
  end

  def to_s
    output  = "#{hostmask} has started a game!  "+
    output += "version => #{@version} " if @version
    output += "started at => #{@start_time.strftime('%I:%M:%S')}"
  end

end
