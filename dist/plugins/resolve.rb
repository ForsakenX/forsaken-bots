class Resolve < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("resolve",self)
  end
  def help(m=nil, topic=nil)
    "resolve [name] => Performs an ip lookup for dns."
  end
  def command m
    return unless target = m.params.shift
    begin
      if target =~ Resolv::AddressRegex
        m.reply Resolv.getname(target)
      else
        m.reply Resolv.getaddress(target)
      end
    rescue Exception
      m.reply "Error: #{$!}"
    end
  end
end
