class Resolve < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("resolve",self)
  end
  def help(m=nil, topic=nil)
    "resolve [name] => Performs an ip lookup for dns."
  end
  def command m
    unless ip = m.params.shift
      m.reply help
    else
      m.reply resolve(ip)
    end
  end
  private
  def resolve ip
    begin
      Resolv.getaddress(ip)
    rescue Exception
      "Error: #{$!}"
    end
  end
end
