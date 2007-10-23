
$event.register('chan.link',Proc.new{|args|
  #
  next if (args.nil? || !args.is_a?(Array))
  (instance,message) = args
  next if self == instance
  #
  channels.each do |name,channel|
    say name, message
  end
})

@event.register('irc.message.privmsg',Proc.new{|m|
  next if m.personal
  message = "#{m.source.nick}: #{m.message}"
  $event.call('chan.link',[self,message])
})

@event.register('irc.message.join',Proc.new{|m|
  next if m.user.nick == @nick
  message = "#{m.user.nick} has entered #{@server[:host]} #{m.channel}"
  $event.call('chan.link',[self,message])
})

@event.register('irc.message.part',Proc.new{|m|
  next if m.user.nick == @nick
  message = "#{m.user.nick} has left #{@server[:host]} #{m.channel}"
  $event.call('chan.link',[self,message])
})

@event.register('irc.message.quit',Proc.new{|m|
  next if m.user.nick == @nick
  message = "#{m.user.nick}: has quit #{@server[:host]}"
  $event.call('chan.link',[self,message])
})

