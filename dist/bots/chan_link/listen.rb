class Listen < Meth::Plugin

  def initialize *args
    super *args
    $event.register('chan.link',Proc.new{|args|
      #
      next if (args.nil? || !args.is_a?(Array))
      (instance,message) = args
      next if self == instance
      #
      @bot.channels.each do |name,channel|
        @bot.say name, message
      end
    })
  end

  def privmsg m
    return if m.personal
    message = "#{m.source.nick}: #{m.message}"
    $event.call('chan.link',[self,message])
  end

  def join m
    return if m.user.nick == @bot.nick
    message = "#{m.user.nick} has entered #{@bot.server[:host]} #{m.channel}"
    $event.call('chan.link',[self,message])
  end

  def part m
    return if m.user.nick == @bot.nick
    message = "#{m.user.nick} has left #{@bot.server[:host]} #{m.channel}"
    $event.call('chan.link',[self,message])
  end

  def quit m
    return if m.user.nick == @bot.nick
    message = "#{m.user.nick}: has quit #{@bot.server[:host]}"
    $event.call('chan.link',[self,message])
  end

end
