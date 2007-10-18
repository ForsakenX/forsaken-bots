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

  # check for "help"
  def privmsg m
    return if m.command
    if m.chomp.message =~ /^help/
      m.reply do_help(m)
    end
  end

  # welcome someone when they join chat
  def join m
    return if m.user.nick.downcase == @bot.nick.downcase
    @bot.say m.user.nick, ""+
       "Hello, I am the forsaken game manager.  "+
       "I help manage and collect information on games.  "+
       "Some of my features include: "+
         "displaying a list of games and their status; "+
         "detecting if someone in the channel is hosting or playing.  "+
       "To Host a game simply say host whenever you see me.  "+
       "You can ask me for status on games too.  "+
       "At a quick glance you can tell how many games are running by my name. "+
       "For more information ask me for help."
  end

end

