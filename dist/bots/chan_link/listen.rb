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
    Irc::Client.clients.each do |name,client|
      return if client.nick.downcase == m.source.nick.downcase
    end
    message = "#{m.source.nick}: #{m.message}"
    $event.call('chan.link',[self,message])
  end
end
