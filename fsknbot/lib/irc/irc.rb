module Irc
end

require 'irc/message_helpers'

require 'irc/helpers'

# event system
require 'irc/timer'

# 
require 'irc/user'
require 'irc/channel'

# handles a message
require 'irc/handle_message'
require 'irc/message' 
require 'irc/privmsg_message'
require 'irc/join_message'
require 'irc/part_message'
require 'irc/quit_message'
require 'irc/kick_message'
require 'irc/notice_message'
require 'irc/topic_message'

# the actual client
require 'irc/client'

