require 'irc'
class MethBot < Irc::Client

  # list of server
  @@servers  = ["irc.blitzed.org:6667"]#,"irc.freenode.net:6667"]

  # setups
  def overide_defaults
    # Override Settings
    @channels = ["#kahn"] # default channels
    @realname = "Meth Killer Bot 0.000001"
    @nick     = "MethBot" # nick of bot
  end

  # we've received a private message
  def privmsg m
    handle_command(m) if m.command
  end

  # we have a command
  def handle_command m
    case m.command
    when "ping"
      m.reply "pong"
    when "hi"
      m.reply "Hey, Whats up!"
    when "ip"
      case m.params[0]
      when "list"
        output = []
        users = Irc::Users.find(:all)
        users.each do |user|
          output << "#{user.nick} => #{user.ip}"
        end
        m.reply "#{users.length} users: #{output.join(', ')}"
      else # when "help"
        m.reply "ip list => Prints a list of users and their ip numbers..."
      end
    else #when "help"
      m.reply "So far I only respond to: help, hi, ping, ip"
    end
  end

end

