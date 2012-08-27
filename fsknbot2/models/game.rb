require "rexml/document"
require 'net/http'

def names_to_s d
	if d.length > 1
		l = d.pop
		n = "#{d.join(',')} and #{l} have"
	else
		n = "#{d} has"
	end
	n
end

#
# Public API
#

class Game
  class << self

    @@games = []; def games; @@games; end

    def update game
      g = Game.create game
      g.last_time = Time.now
 		  Game.publish if g.valid # updates if user opened port
    end

    def create game
      unless g = Game.find(game[:ip], game[:port])
        g = Game.new(game)
        @@games << g
				if g.valid
        	IrcConnection.privmsg "#forsaken", "Game started #{g.to_s}"
				else
        	IrcConnection.privmsg "#forsaken",
						"A game has started "+
						"but the port is closed so nobody can join... "+
						"#{g.name}@#{g.ip} (#{g.version}) #{g.country}"
				end
      end
			if (a=g.names[1..-1].compact.sort) != (b=game[:names][1..-1].compact.sort)
				puts "game: #{g.name} before = #{a.join ','} after = #{b.join ','}"
				if not (d=a-b).empty?
					IrcConnection.privmsg "#forsaken",
						"#{names_to_s d} left #{g.name}'s game."
				end
				if not (d=b-a).empty?
					IrcConnection.privmsg "#forsaken",
						"#{names_to_s d} joined #{g.name}'s game."
				end
			end
			g.names = game[:names]
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
      IrcConnection.privmsg "#forsaken", "Game #{g.name} closed" if g.valid
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
				next unless game.valid
        time = game.start_time.to_i if game.start_time
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
			next unless game.valid
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
  attr_accessor :last_time, :open, :country, :names

  def initialize game
    @version     = game[:version]
    @name        = game[:name]
		@names       = game[:names]
    @ip          = game[:ip]
		begin
			@country   = Net::HTTP.get_response(URI.parse(
				"http://api.hostip.info/get_html.php?ip=#{game[:ip]}&position=true"
			)).body.gsub(/\s+/," ").gsub(/City.*/,'').strip
		rescue Exception
			@country   = "Unknown"
		end
    @port        = game[:port]
    @start_time  = Time.now
    @last_time	 = @start_time
    @url	 = "fskn://#{@ip}:#{@port}?version=#{@version}"
    @hostname	 = "#{@name}@#{@url}"
	end

	def valid
		@valid ||= begin
			output=`#{ROOT}/plugins/test/test #{@ip} #{@port} 2>&1`
			$? == 0
		end
	end

  def destroy
    Game.destroy_game self
  end

	def players
		@names[1..-1]
	end

  def to_s
   	"#{@name} @ #{@url} #{@country} players: #{players.empty? ? "(none)" : players.join(',')}"
  end

end
