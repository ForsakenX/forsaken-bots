class Meth::CommandManager

  attr_reader :commands

  def initialize(client)
    @client = client
    @commands = {}
    @client.event.register('irc.message.privmsg',Proc.new{|m| privmsg m })
  end

  def register(cmd,obj,callback=nil)
    callback = Proc.new{|m| obj.command(m) } if callback.nil?
    @commands[cmd] = { 
      :obj => obj,
      :callback => callback
    }
    @client.event.register("meth.command.#{cmd}",callback)
  end

  def cleanup obj
    @commands.each do |cmd,h|
      if h[:obj] == obj
        @client.event.unregister("meth.command.#{cmd}",h[:callback])
        @commands.delete(cmd) 
      end
    end
  end

  def privmsg m
    c = Meth::Command.new(@client,m.line,m.time)
  end

end
