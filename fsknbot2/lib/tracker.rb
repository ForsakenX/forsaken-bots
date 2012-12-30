class GameTracker < EM::Connection
	include EM::Protocols::LineText2

	def receive_line line
		peer = Socket.unpack_sockaddr_in(get_peername)
		port,ip = peer
		puts "peer: {port=#{port}, ip=#{ip}}, data: #{line}"
		parts = line.split # safe from \r injection
		state = parts.shift
		case state
		when "hosting"
			port    = parts.shift
			version = parts.shift
			# some bastards have spaces in their names
			# so we have to assume that the last part is the level name
			level   = parts.pop
			names   = parts.join(' ').split ',' 
			return if port.nil? or names.empty? or version.nil?
			Game.update({ 
				:ip      => ip,
				:port    => port,
				:version => version,
				:name    => names.first,
				:names   => names,
				:level   => level
			})
		when "finished"
			port = parts.shift
			return if port.nil?
			Game.destroy ip, port
		when "ping"
			send_data "pong\n"
		end
	end

	def self.check
		t = Time.now
		puts "GameTracker checking games"
		Game.games.dup.each do |game|
			timeout_range = Time.now - 60
			if game.last_time < timeout_range
				game.destroy
			end
		end
		puts "GameTracker check took #{Time.now-t} seconds"
	end
end

$run_observers << Proc.new {
	begin
		EM::open_datagram_socket "0.0.0.0", 47624, GameTracker
		EM::PeriodicTimer.new( 60 ) do # every minute
			GameTracker.check
		end
	rescue
		puts "Failed to setup GameTracker..."
		exit 1
	end
}
