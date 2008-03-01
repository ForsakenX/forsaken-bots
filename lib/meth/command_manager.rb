class Meth::CommandManager

  attr_reader :commands

  def initialize(bot)
    @bot = bot
    @commands = {}
    @bot.event.register('irc.message.privmsg',Proc.new{|m| privmsg m })
  end

  def register(cmd,obj,callback=nil)
    callback = Proc.new{|m| obj.command(m) } if callback.nil?
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
    c = Meth::Command.new(@bot,m.line)
  end

end
