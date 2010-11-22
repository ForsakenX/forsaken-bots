
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
      "help [command] (for help on specific command), "+
			"list of commands and aliases: #{commands.join(', ')}"
    end

    def commands
      IrcCommandManager.aliases.keys.sort.map do |command|
				aliases = IrcCommandManager.aliases[command].join(';')
				aliases.empty? ? command : command + " (#{aliases})"
			end
    end

    def not_found
      "Command not found: #{commands.join(', ')}"
    end

  end
end
