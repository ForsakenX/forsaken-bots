class Help
  def help m
    if (plugin = m.params.shift)
      m.command = plugin
      Meth::Plugins.do(m.command,'help',m)
    else
      "help [command] => return help on a command... "+
      "Current commands are: #{Meth::Plugins.list.join(', ')}"
    end
  end
  def privmsg m
    m.reply help(m)
  end
end
