class Help < Meth::Plugin
  def help m=nil
    "help [command] => return help on a command.  "+
    "If [command] is ommited then help returns a list of help topics."
  end
  def do_help m
    if (plugin = m.params.shift)
      @bot.plugins[plugin].send('help',m)
    else
      "Help Topics: #{@bot.plugin_manager.enabled.join(', ')}"
    end
  end
  def command m
    m.reply do_help(m)
  end
end
