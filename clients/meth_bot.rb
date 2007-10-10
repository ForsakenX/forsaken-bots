class MethBot < IrcClient

  # list of server
  @@servers  = ["irc.blitzed.org:6667"]#,"irc.freenode.net:6667"]

  # setups
  def overide_defaults
    # Override Settings
    @channels = ["#kahn"] # default channels
    @realname = "Meth Killer Bot 0.000001"
    @nick     = "MethBot" # nick of bot
  end

  # we've received a new message
  def privmsg(command,channel,params)
    handle_command(command,channel,params) if command
  end

  # we've recieved a command
  def handle_command(command,channel,params)
    case command
    when "ping"
      say channel, "pong"
    when "hi"
      say channel, "Hey, Whats up!"
    when "ip"
      command = params.shift
      case command
      when "list"
        output = []
        users = Users.find(:all)
        users.each do |user|
          output << "#{user.nick} => #{user.ip}"
        end
        say channel, "#{users.length} users: #{output.join(', ')}"
      else # when "help"
        say channel, "ip list => Prints a list of users and their ip numbers..."
      end
    else #when "help"
      say channel, "So far I only respond to: help, hi, ping, ip"
    end
  end

end

