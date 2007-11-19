class Fortune < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("fortune",self)
  end
  def help(m=nil, topic=nil)
    "fortune => Displays a fortune."
  end
  def command m
    begin
      m.reply `fortune`.gsub(/\n/,' ')
    rescue Exception
      m.reply "#{$!}"
    end
  end
end
