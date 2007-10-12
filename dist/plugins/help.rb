class Help < Meth::Plugin
  def help m=nil
    "help [command] => return help on a command.  "+
    "If [command] is ommited then help returns a list of help topics."
  end
  def do_help m
    if (plugin = m.params.shift)
      m.command = plugin
      Meth::PluginManager.do(m.command,'help',m)
    else
      "Help Topics: #{Meth::PluginManager.enabled.join(', ')}"
    end
  end
  def privmsg m
    m.reply do_help(m)
  end
end
