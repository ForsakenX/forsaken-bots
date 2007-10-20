class Help < Meth::Plugin

  # help for this plugin
  def help m=nil
    "help [command] => return help on a command.  "+
    "If [command] is ommited then help returns a list of commands."
  end

  # get the help message of another plugin
  def do_help m
    if (plugin = m.params.shift)
      @bot.plugins[plugin].send('help',m)
    else
      "Commands: #{@bot.plugin_manager.enabled.join(', ')}.  "+
      "If you don't know what to do next type 'help help'"
    end
  end

  # if we've been requested directly
  def command m
    m.reply do_help(m)
  end

end
