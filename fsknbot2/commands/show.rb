IrcCommandManager.register 'show', 'admin tools' do |m|

  # authorize user
  return unless m.from.authorized?

  # parse sub command
  case m.args.first

    # show authorized list
    when 'authorized'
      m.reply IrcUser.authorized.join(', ')

    # send back user list
    when 'users'
      m.reply IrcUser.users.map{|u|u.nick}.join(', ')

    # get a specific user
    when 'user'
      m.reply IrcUser.find_by_nick(m.args[1]).inspect

    # send command list
    when 'commands'
      m.reply IrcCommandManager.commands.keys.join(', ')

    # show help
    else
      m.reply "authorized|users|user|commands"

  end

end
