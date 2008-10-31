
require 'irc_handle_line'

IrcHandleLine.events[:message].register do |args|
  next unless args[:to] == $nick
  next if args[:from].downcase == 'methods'
  IrcConnection.privmsg 'methods', "#{args[:from]}: #{args[:message]}"
end

