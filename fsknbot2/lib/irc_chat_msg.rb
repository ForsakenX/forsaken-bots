require 'observe'
require 'irc_user'
require 'irc_connection'
require 'irc_handle_line'
require 'irc_command_manager'

#
# Instance
#

class IrcChatMsg

  # listener
  IrcHandleLine.events[:message].register do |args|
    self.new( args )
  end

  ## public api
  @@observer = Observe.new
  def self.register(&block); @@observer.register(&block); end

  ## readers
  attr_reader :prefix, :from, :to, :message, :line, :channel,
              :targeted, :private, :command, :args, :type, :time

  ## instance constructor
  def initialize hash

   ## only handle $channels or private messages
   return unless [$nick,$channels].flatten.include? hash[:to].downcase

   ## get user message came from
   ## only handle messages for users we know 
   return unless @from = IrcUser.find_by_nick(hash[:from])

   ## save the raw line
   @line = hash[:line]

   ## save the message
   @message = hash[:message]

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
   message = hash[:message].dup.sub(/^\s+/,'')

   ## check for name with optional colon
   message.sub!(/^#{$nick}:? /i,'') if message.split.first =~ /#{$nick}:?/i

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
     @command = (@args.shift||'').downcase

			##
			return if @from.ignored

# TODO should also fork listeners ?

# fork so plugins can't slow down core bot
_t=Time.now
parent_id=$$
pid = fork {
puts "forked `#{@command}` as id #{$$} for parent #{parent_id} took #{Time.now-_t} seconds"

# over write send methods
@hash = hash
def reply m
	if @hash[:replier]
		@hash[:replier].call(m)
	else
		require 'socket'
		$s = TCPSocket.new('localhost',6668)
		$s.puts m
		$s.close
	end
end
def reply_directly m; true; end # disabled

     ## call command
     IrcCommandManager.call(@command,self)

puts "forked child exiting took #{Time.now-_t} seconds"
exit 0
}
puts "about to detach child at #{Time.now-_t} seconds"
Process.detach pid # let init become parent
puts "detached child at #{Time.now-_t} seconds"

   end

   ## call listeners
   @@observer.call self

  end

  ## auto reply to @reply_to
  def reply message
    IrcConnection.privmsg @reply_to, message
  end

  ## reply to sender directly
  def reply_directly message
    IrcConnection.privmsg @from.nick, message
  end

end
