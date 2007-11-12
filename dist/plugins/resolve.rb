class Resolve < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("resolve",self)
  end
  def help(m=nil, topic=nil)
    "resolve [dns] => Performs an ip lookup for dns."
  end
  def do_help m
    if (ip = m.params[0])
      begin
        return Resolv.getaddress ip
      rescue Exception
        "Error: #{$!}"
      end
    else
      help
    end
  end
  def command m
    m.reply do_help(m)
  end
end
