IrcCommandManager.register 'show', 'admin tools' do |m|

  ## authorize user
  return unless m.from.nick == 'methods'

  ## parse sub command
  case m.args[0]

    ## send back user list
    when 'users'
      m.reply IrcUser.users.map{|u|u.nick}.join(', ')

    ## get a specific user
    when 'user'
      m.reply IrcUser.find_by_nick(m.args[1]).inspect

    ## send back topic
    when 'topic'
      m.reply IrcTopic.topic

    ## send command list
    when 'commands'
      m.reply IrcCommandManager.commands.keys.join(', ')
      
  end

end
