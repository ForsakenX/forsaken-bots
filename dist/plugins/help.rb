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
    if (command = m.params[0])
      if a = @bot.plugin_manager.plugins['alias'].aliases[command]
        m.reply "#{command} is an alias for #{a}"
      end
      @bot.command_manager.commands[command][:obj].help(m,a)
    else
      "Commands: #{@bot.command_manager.commands.keys.sort.join(', ')}.  "+
      "Type 'help help' if you don't know what to do next."
    end
  end
  def command m
    m.reply do_help(m)
  end
end
