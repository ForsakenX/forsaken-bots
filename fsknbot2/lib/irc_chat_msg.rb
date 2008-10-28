require 'irc_user'
require 'irc_connection'
require 'irc_command_manager'
class IrcChatMsg

  ## readers
  attr_reader :prefix, :from, :to, :message, :channel,
              :targeted, :private, :command, :args, :type

  ## instance constructor
  def initialize hash

   ## only handle $channel or private messages
   return unless [$nick,$channel].include? hash[:to]

   ## get user message came from
   ## only handle messages for users we know 
   return unless @from = IrcUser.find_by_nick(hash[:from])

   ## save the type
   @type = hash[:type]

   ## the target of the message
   @to = hash[:to]

   ## if we are in channel or not
   @channel = @to[0] == '#'[0]
   @private = !@channel

   ## set reply to
   @reply_to = @channel ? @to : @from.nick

   ## temp message var for cutting up command|args
   message = hash[:message].dup

   ## check for name with optional colon
   message.sub!(/^#{$nick}:? /,'') if message.split.first =~ /#{$nick}:?/

   ## check for notifier
   message.sub!(/^#{$prefix}/,'') if $prefix && message[0] == $prefix[0]

   ## if we are targetted by this message
   ## always targeted in non channel
   @targeted = $prefix.nil? || @private || message.length < hash[:message].length

   ## parse out command and args if targted
   @command = nil
   @args = []
   if @targeted

     ## args is list of words
     @args = message.split.compact

     ## command is first word
     @command = @args.shift

     ## call command
     IrcCommandManager.call @command.to_sym, self

   end

  end

  ## auto reply to @reply_to
  def reply message
    IrcConnection.privmsg @reply_to, message
  end

end
