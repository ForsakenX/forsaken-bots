
IrcCommandManager.register 'help' do |m|
  m.reply HelpCommand.run(m.args[0])
end

class HelpCommand
  class << self

    def run command
      help(command) || not_found
    end

    def help command
      (command||'help') == 'help' ? helphelp : IrcCommandManager.help[ command ]
    end

    def helphelp
      "Help shows help on commands.  "+
      "Syntax: help [command].  "+
      "Commands: #{commands.join(', ')}"
    end

    def commands
      IrcCommandManager.commands.keys
    end

    def not_found
      "Command not found: #{commands.join(', ')}"
    end

  end
end

