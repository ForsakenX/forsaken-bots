class MethBot < IrcClient

  # Settings
  @@servers  = ["irc.blitzed.org:6667"]#,"irc.freenode.net:6667"] # list of servers
  @@channels = ["#kahn","#rbot"] # default channels
  @@realname = "Meth Killer Bot 0.000001"
  @@nick     = "MethBot" # nick of bot

  # we've received a new message
  def privmsg(command,channel,message)
    case command
    when "help"
      say channel, "So far I only respond to: help, hi, ping, users"
    when "ping"
      say channel, "pong"
    when "hi"
      say channel, "Hey, Whats up!"
    when "users"
      output = []
      @users.each do |user|
        output << "#{user.nick} => #{user.ip}"
      end
      say channel, "Total #{@users.length} users: #{output.join(', ')}"
    end
  end

end

