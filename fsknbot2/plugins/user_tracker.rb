$run_observers << Proc.new {
	EM::PeriodicTimer.new( 60 ) do # every minute
		begin
			now   = Time.now
			users = IrcUser.users.map {|u| u.nick }
			path  = File.expand_path "#{ROOT}/db/users.txt"
			line  = "#{now.strftime('%s')} #{users.length - 1} #{users.join ','} # #{now}"
			file  = File.open(path,'a+')
			file.puts line
			file.close
			#puts "Login tracker logged: #{line}"
		rescue
    	puts_error(__FILE__,__LINE__)
		end
	end
}
