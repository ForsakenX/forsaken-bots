
IrcCommandManager.register 'help' do |m|
  m.reply HelpCommand.run( m.args.first ? m.args.first.downcase : '' )
end

class HelpCommand
  class << self

    def run command=''
      help(command) || not_found
    end

    def help command
      if [nil,'','help'].include?(command)
        helphelp
      else
        IrcCommandManager.help[ command ]
      end
    end

    def helphelp
      "help [command].  "+
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

