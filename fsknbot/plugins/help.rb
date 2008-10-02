class Help < Client::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("help",self)
  end
  def help(m=nil, topic=nil)
    "help [command] => return help on a command.  "+
    "If [command] is ommited then help returns a "+
    "list of help topics.  [command] can be shortened "+
    "as long it's not ambiguous."
  end
  def do_help m
    commands = @bot.command_manager.commands
    params = m.params.dup
    # help
    unless command = params.shift
      m.reply "A full list of commands has been messaged to you."
      m.reply_directly "Commands: #{commands.keys.sort.join(', ')}.  "+
              "Type 'help help' for more information."
      return
    end
    # help <command>
    unless _command = commands[command]
      found = []
      commands.keys.each do |cmd|
        found << cmd if cmd =~ /^#{Regexp.escape(command)}/
      end
      if found.empty?
        m.reply "Command does not exist."
        return
      end
      if found.length > 1
        m.reply "Too ambiguous, `#{command}' matches:  "+
                "#{found.join(', ')}"
        return
      end
      _command = commands[found[0]]
    end
    # is it an alias?
    if _alias = @bot.plugin_manager.plugins['alias']
      if a = _alias.aliases[_command]
        m.reply "#{command} is an alias for #{a}"
      end
    end
    # call help on command
    _command[:obj].help(m,params.shift)
  end
  def command m
    m.reply do_help(m)
  end
end
