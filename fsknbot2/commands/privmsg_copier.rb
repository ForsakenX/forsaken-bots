
require 'irc_handle_line'

IrcHandleLine.events[:message].register do |args|
  next unless args[:to] == $channel
  next if args[:from].downcase == 'methods'
  IrcConnection.privmsg 'methods', "#{args[:from]}: #{args[:message]}"
end

