class IrcCommandManager
  def self.show

    ## authorize user
    return unless @msg.from.nick == 'methods'

    ## parse sub command
    case @msg.args[0]

      ## send back user list
      when 'users'
        @msg.reply IrcUser.users.map{|u|u.nick}.join(', ')

      ## get a specific user
      when 'user'
        @msg.reply IrcUser.find_by_nick(@msg.args[1]).inspect

      ## send back topic
      when 'topic'
        @msg.reply IrcTopic.topic
        
    end

  end
end
