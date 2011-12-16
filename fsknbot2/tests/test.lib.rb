
ROOT = File.dirname(__FILE__) + "/../"
require "#{ROOT}/config/environment"

class EM::Connection
	# stop EM from complaining about no connection
	def send_data *args
	end
end

class IrcConnection
	def send_line msg=""
		puts "send_line => #{msg}"
	end
end

puts "creating fake EM connection"
$connection = IrcConnection.new( "fake_em_signature" )

puts "creating some fake users"
$user_1 = IrcUser.create({ :nick => "user_1", :host => "user_1@test.com" })
$user_2 = IrcUser.create({ :nick => "user_2", :host => "user_2@test.com" })
$user_3 = IrcUser.create({ :nick => "user_3", :host => "user_3@test.com" })

puts "runnig test"
