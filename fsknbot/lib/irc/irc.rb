module Irc
end

require 'irc/message_helpers'
require 'irc/helpers'
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

require 'irc/client'
require 'irc/command'
require 'irc/command_manager'
require 'irc/plugin_manager'
require 'irc/plugin'

