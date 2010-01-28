require "rexml/document"

#
# Public API
#

class Game
  class << self

    @@games = []; def games; @@games; end

    def update game
      g = Game.create game
      g.last_time = Time.now
    end

    def create game
      unless g = Game.find(game[:ip], game[:port])
        g = Game.new(game)
        @@games << g
    	Game.publish
        IrcConnection.privmsg "#forsaken", "Game started #{g.to_s}"
      end
      g
    end

    def destroy ip, port
      if g = Game.find(ip, port)
	g.destroy
      end
      g
    end

    def destroy_game g
      @@games.delete g
      Game.publish
      IrcConnection.privmsg "#forsaken", "Game #{g.name} closed"
      g
    end

    def find ip, port
      @@games.detect do |game|
        game.ip == ip and game.port == port
      end
    end

    def length
      @@games.length
    end

    def publish_xml
      doc = REXML::Document.new
      games = doc.add_element("games")
      @@games.each do |game|
        time = game.start_time.strftime("%a, %d %b %Y %H:%M:%S GMT-0400") if game.start_time
        games.add_element("game",{ "nick" => game.name,
                                   "ip"   => game.ip,
                                   "port" => game.port,
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

	def publish_json
		games = []
		@@games.each do |game|
        		time = game.start_time.strftime("%a, %d %b %Y %H:%M:%S GMT-0400") if game.start_time
			games << {
				:nick => game.name,
				:ip => game.ip,
				:port => game.port,
				:version => game.version,
				:started_at => time
			}
		end
		output = "{\n"
		games.each_with_index do |game,x|
			output += "{\n"
			game.keys.each_with_index do |key,i|
				output += "\t"
				output += "#{key}='#{game[key]}'"
				output += "," unless (i == game.keys.length - 1)
				output += "\n"
			end
			output += "}"
			output += "," unless (x == games.length - 1)
			output += "\n"
		end
		output += "}\n"
		begin
			file = File.open( File.expand_path( "#{ROOT}/db/games.json" ), 'w+' )
			file.write output
			file.close
		rescue Exception
			puts "Error Saving games.json: #{$!}"
		end
	end

    def publish
      publish_json
      publish_xml
    end

  end
end

#
# Instance
#

class Game

  attr_reader :hostname, :start_time, :name, :ip, :port, :url, :version
  attr_accessor :last_time

  def initialize game
    @version     = game[:version]
    @name        = game[:name]
    @ip          = game[:ip]
    @port        = game[:port]
    @start_time  = Time.now
    @last_time	 = @start_time
    @url	 = "fskn://#{@ip}:#{@port}?version=#{@version}"
    @hostname	 = "#{@name}@#{@url}"
  end

  def destroy
    Game.destroy_game self
  end

  def to_s
    "#{@name} @ #{@url}"
  end

end
