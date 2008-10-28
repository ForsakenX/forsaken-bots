require 'irc_user'
require 'irc_chat_msg'
require 'irc_connection'
class IrcHandleLine

  ## parse incoming line
  def initialize line

    ## cut up the line
    @parts = line.downcase.split(' ')

    ## first part of line is hostname of server or user_tag
    ## server == :koolaid.ny.us.blitzed.org
    ## user_tag == :nick![n|y]=uid@hostname
    ## extract nick only for now
    @parts.shift =~ /:([^!]+)/
    @nick = $1 # nick or hostname of server

    ## 2nd part of line is the irc action
    @action = @parts.shift

    ## handle the action
    case @action

      ## handle nick change
      when 'nick'

        ## strip off new name
        new = @parts.shift.sub(/^:/,'')

        ## send to user manager
        user = IrcUser.find_by_nick @nick

        ## change the nick
        user.nick = new

      ## handle who responses
      when '352'

        ## split line
        me,channel,user,host,server,nick,shit,hops,realname = @parts

        ## we only care about one channel
        return if channel != $channel

        ## find user
        if user = IrcUser.find_by_nick(nick)
          user.host = host

        ## create user
        else
          user = IrcUser.new :nick => nick, :host => host
        end

      ## handle join
      when 'join'

        ## we only care about $channel
        return unless @parts.shift.sub(/^:/,'') == $channel

        ## we just joined 
        if @nick == $nick

          ## ask for details on all users in room
          IrcConnection.who $channel

        ## someone else joined
        else

          ## ask for details on user
          ## who response will create user
          IrcConnection.who @nick

        end

      ## user left channel
      when 'part'

        ## we only care about $channel
        return unless @parts.shift == $channel

        ## remove user
        IrcUser.delete_by_nick @nick

      ## user quit irc
      when 'quit'

        ## remove user
        IrcUser.delete_by_nick @nick

      ## user was kicked
      when 'kick'

        ## we only care about $channel
        return unless @parts.shift == $channel

        ## get rid of user
        IrcUser.delete_by_nick @parts.shift

      ## handle message
      when 'privmsg','notice'

        ## parse target (me|channel)
        target = @parts.shift

        ## parse message
        message = @parts.join(' ').sub(/^:/,'')

        ## pass to chat message handler
        IrcChatMsg.new :to => target, :from => @nick,
                       :type => @action, :message => message

      ## handle topic messages
      when 'topic','332'

        ## your own nick -- uneeded
        @parts.shift if @action == '332'

        ## we only care about $channel
        return unless @parts.shift == $channel

        ## set topic
        IrcTopic.topic = @parts.join(' ').sub(/^:/,'')

    end

  end

end
