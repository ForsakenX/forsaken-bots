require 'observe'
require 'irc_user'
require 'irc_connection'
require 'irc_handle_line'
require 'irc_command_manager'

#
# Listener
#

IrcHandleLine.events[:message].register do |args|

	# parse message
	m = IrcChatMsg.new( args )

	# ignored?
	if m.ignored
		puts "--- Message Ignored"
		next
	end

	# call command
	IrcCommandManager.call( m.command, m ) if m.targeted

	# call listeners
	IrcChatMsg.observer.call( m )

end

#
# Instance
#

class IrcChatMsg

	#
	# Observer
	#

	@@observer = Observe.new
	def self.observer; @@observer; end
	def self.register(&block); @@observer.register(&block); end

	#
	# Instance
	#

	attr_reader :from, :to, :message, :line, :channel, :ignored,
		    :targeted, :private, :command, :args, :type, :time,
		    :valid_target

	def initialize m

		# save the raw data
		@to      = m[:to]	|| ""
		@line    = m[:line]	|| ""
		@type    = m[:type]	|| "privmsg"
		@message = m[:message]
		@ignored = false # invalid target or unkown user

		# get user message came from
		if @from = IrcUser.find_by_nick( m[:from] )
			@ignored = true if @from.ignored
		else
			@from = IrcUser.new({ :nick => m[:from] })
			@ignored = true
		end

		# valid target is $channels we are in or pm
		valid_targets = [$nick,$channels].flatten
		@valid_target = valid_targets.include? @to.downcase
		@ignored = true unless @valid_target

		# if we are in channel or private message
		@channel = @to[0] == '#'[0]
		@private = !@channel

		# set reply to variable
		@reply_to = @channel ? @to : @from.nick

		# temp message var for cutting up command and args
		message = m[:message].dup.sub(/^\s+/,'')

		# check for name with optional colon
		if message.split.first =~ /#{$nick}:?/i
			message.sub!(/^#{$nick}:? /i,'')
		end

		# check for prefix
		prefixed = false
		if $prefix && message[0] == $prefix[0]
			message.sub!(/^#{$prefix}/,'')
			prefixed = true
		end

		# if we are targetted by this message
		@targeted = $prefix.nil? || @private || prefixed

		# default not a command and no args
		@command = nil
		@args = []

		# parse out command and args if targted
		if @targeted

			# args is list of words
			@args = message.split.compact

			# command is first word
			@command.downcase! if @command = @args.shift

		end

	end

	def reply message
		IrcConnection.privmsg @reply_to, message
	end

	def reply_directly message
		IrcConnection.privmsg @from.nick, message
	end

end

