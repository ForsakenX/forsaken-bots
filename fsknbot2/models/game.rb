require "rexml/document"

#
# Public API
#

class Game
  class << self

    @@games = []; def games; @@games; end

    def create game
      unless g = Game.find(game[:ip], game[:port])
        g = Game.new(game)
        @@games << g
    	Game.update
      end
      g
    end

    def find ip, port
      @@games.detect do |game|
        game.ip == ip
        game.port == port
      end
    end

    def length
      @@games.length
    end

    def update
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

  attr_reader :hostname, :start_time, :name, :ip, :url, :version

  def initialize game
    @version     = game[:version]
    @name        = game[:name]
    @ip          = game[:ip]
    @port        = game[:port]
    @start_time  = Time.now
    @url	 = "fskn://#{@ip}"
    @hostname	 = "#{@name}@#{@ip}:#{@port}"
  end

  def destroy
    @@games.delete(self)
    Game.update
    self
  end

  def to_s
    "#{@name} @ #{@url} version: #{@version}"
  end

end
