class GameTracker < EM::Connection
	include EM::Protocols::LineText2

	@@hosts = {}

	def receive_line line
		peer = Socket.unpack_sockaddr_in(get_peername)
		port,ip = peer
		puts "peer: {port=#{port}, ip=#{ip}}, data: #{line}"
		parts = line.split
		state = parts.shift
		case state
		when "hosting"
			version = parts.shift
			Game.create({ 
				:ip => ip,
				:port => port,
				:version => version
			})
			@@hosts[peer] = Time.now
		when "finished"
			Game.destroy ip
			@@hosts.delete peer
		end
	end

	def self.check
		@@hosts.dup.each do |peer,last_time|
			time_range = Time.now - 60
			if last_time < time_range
				ip = peer[1]
				Game.detroy ip
				@@hosts.delete peer
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
		puts "Failed to open datagram socket for GameTracker..."
		exit 1
	end
}
