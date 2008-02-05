class Help < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("help",self)
  end
  def help(m=nil, topic=nil)
    "help [command] => return help on a command.  "+
    "If [command] is ommited then help returns a list of help topics.  "
  end
  def do_help m
    unless command = m.params.shift
      m.reply "Commands: #{@bot.command_manager.commands.keys.sort.join(', ')}.  "+
              "Type 'help help' if you don't know what to do next."
      return
    end
    unless command = @bot.command_manager.commands[command]
      m.reply "Command does not exist."
      return
    end
    if a = @bot.plugin_manager.plugins['alias'].aliases[command]
      m.reply "#{command} is an alias for #{a}"
    end
    command[:obj].help(m,a)
  end
  def command m
    m.reply do_help(m)
  end
end
