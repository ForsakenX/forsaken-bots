class Meth::CommandManager

  attr_reader :commands

  def initialize(bot)
    @bot = bot
    @commands = {}
    @bot.event.register('irc.message.privmsg',Proc.new{|m| privmsg m })
  end

  def register(cmd,obj,callback=Proc.new{|m| obj.command(m) })
    @commands[cmd] = { 
      :obj => obj,
      :callback => callback
    }
    @bot.event.register("meth.command.#{cmd}",callback)
  end

  def cleanup obj
    @commands.each do |cmd,h|
      if h[:obj] == obj
        @bot.event.unregister("meth.command.#{cmd}",h[:callback])
        @commands.delete(cmd) 
      end
    end
  end

  def privmsg m


    # m.message with a command is one of the following
    # ",hi 1 2 3"
    # "MethBot: hi 1 2 3"

    # must become...
    # m.command => hi
    # m.message => 1 2 3

    # look for our nick or target as first word
    # then extract them from the message
    # "(<nick>: |<target>)"
    unless is_command = !m.message.slice!(/^#{Regexp.escape(@bot.nick)}: /).nil?
      # addressed to target
      unless @bot.target.nil?
        is_command = !m.message.slice!(/^#{Regexp.escape(@bot.target)}/).nil?
      end
    else
      named = true
    end

    # "hi 1 2 3"
    # now that nick/target is extracted
    # thats how the message looks
    # includes the command and params

    # if its a pm then its allways a command
    is_command = m.personal if !is_command

    # %w{hi 1 2 3}
    # split words in line
    params = m.line.split(' ')
    m.instance_variable_set(:@params,params)
    class <<m; attr_accessor :params; end

    # "hi"
    # the command
    # so do we have a command?
    command = is_command ? m.params.shift : nil
    m.instance_variable_set(:@command,command)
    class <<m; attr_accessor :command; end

    # was our name addressed?
    m.instance_variable_set(:@named,named)
    class <<m; attr_accessor :named; end

    # m.message is now the command params
    # m.command is now the command
    # m.params is now an array of words after the command

    # call easy to use command event
    if m.command
      @bot.logger.info "Command called: #{m.command.downcase}"
      @bot.event.call("meth.command.#{m.command.downcase}",m)
    end

  end

end
