
require 'irc_handle_line'

IrcHandleLine.events[:message].register do |args|
  next if args[:from] == 'methods'
  IrcConnection.privmsg 'methods', "#{args[:from]}: #{args[:message]}"
end

