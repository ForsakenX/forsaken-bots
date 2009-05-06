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
			port = parts.shift
			version = parts.shift
			name = parts.join
			return if port.nil? or name.nil? or version.nil?
			Game.update({ 
				:ip => ip,
				:port => port,
				:version => version,
				:name => name
			})
		when "finished"
			port = parts.shift
			return if port.nil?
			Game.destroy ip, port
		end
	end

	def self.check
		puts "GameTracker checking games"
		Game.games.dup.each do |game|
			timeout_range = Time.now - 60
			if game.last_time < timeout_range
				game.destroy
			end
		end
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
