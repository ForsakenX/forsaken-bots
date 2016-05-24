require 'observe'
require 'irc_user'
require 'irc_connection'

#
# Public API
#

class IrcHandleLine
  class << self

    @@events = {
      :join    => Observe.new,
      :part    => Observe.new,
      :message => Observe.new,
      :topic   => Observe.new,
      :end_who_list => Observe.new,
    }

    def events; @@events; end

  end
end

#
# Instance
#

class IrcHandleLine

  ## parse incoming line
  def initialize line

    ## save message time
    @time = Time.now

    ## save original line
    original_line = line.dup

    ## cut up the line
    @parts = line.split(' ')

    ## pings
    if @parts.first.downcase == "ping"
      @parts.shift
      IrcConnection.pong @parts.join(' ')
      return
    end

    ## first part of line is hostname of server or user_tag
    ## server == :koolaid.ny.us.blitzed.org
    ## user_tag == :nick![n|y]=uid@hostname
    ## extract nick only for now
    @parts.shift =~ /:([^!]+)/
    @nick = $1 # nick or hostname of server

    ## 2nd part of line is the irc action
    @action = @parts.shift.downcase

    ## debug info
    puts "action = #{@action}"

    ## handle the action
    case @action

      ## handle pong messages
      when 'pong'
        IrcConnection.last_pong_time = Time.now

      ## handle nick change
      when 'nick'

        ## strip off new name
        new = @parts.shift.sub(/^:/,'')

        ## send to user manager
        if user = IrcUser.find_by_nick(@nick)

          ## change the nick
          user.nick = new

        end

      ## end of who list
      when '315'

        self.class.events[:end_who_list].call

      ## handle who responses
      when '352'

        ## line parts
        @parts.shift # my name - uneeded
        channel  = @parts.shift.downcase # channel name
        user     = @parts.shift # n=mr_term
        host     = @parts.shift # hostname
        server   = @parts.shift # irc server
        nick     = @parts.shift # user nick
        flags    = @parts.shift # (H|G)
        hops     = @parts.shift # :0
        realname = @parts.join(' ') # freeform

        ## alloud channels
        return unless $channels.include? channel

        ## find user
        if user = IrcUser.find_by_nick(nick)
          user.host = host

        ## create user
        else
          user = IrcUser.new :nick => nick, :host => host
        end

      ## handle join
      when 'join'

        ## alloud channels
        channel = @parts.shift.sub(/^:/,'').downcase
        return unless $channels.include? channel

        ## send join event
        self.class.events[:join].call(channel,@nick)

        ## we just joined 
        if @nick.downcase == $nick

          ## ask for details on all users in room
          IrcConnection.who channel

        ## someone else joined
        else

          ## ask for details on user
          ## who response will create user
          IrcConnection.who @nick

        end

      ## user left channel
      when 'part'

        channel = @parts.shift.downcase

        ## send part events
        self.class.events[:part].call(channel,@nick)

        ## allowed channels
        return unless $channels.include? channel

        ## remove user
        IrcUser.delete_by_nick @nick

      ## user quit irc
      when 'quit'

        ## remove user
        IrcUser.delete_by_nick @nick

      ## user was kicked
      when 'kick'

        ## allowed channels
        return unless $channels.include? @parts.shift.downcase

        ## get rid of user
        IrcUser.delete_by_nick @parts.shift

      ## handle message
      when 'privmsg','notice'

        ## parse target (me|channel)
        target = @parts.shift

        ## parse message
        message = @parts.join(' ').sub(/^:/,'')

        ## args to pass
        args = {:time => @time,
                :to   => target,
                :from => @nick,
                :type => @action,
                :line => original_line,
                :message => message}

        ## send message event
        self.class.events[:message].call args

      ## handle topic messages
      when 'topic','332'

        ## your own nick -- uneeded
        @parts.shift if @action == '332'

        # parse channel
        channel = @parts.shift.downcase

        # the topic
        topic = @parts.join(' ').sub(/^:/,'')

        # args
        args = { :channel => channel,
                 :setter  => @nick, 
                 :topic   => topic }

        ## set topic
        self.class.events[:topic].call( args )

    end

  end

end
