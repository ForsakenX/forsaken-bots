class ChanLink < Meth::Plugin

  def initialize *args
    super *args
    setup_events if @bot.name != 'fskn_bot_games'
  end

  def cleanup *args
    super *args
  end

  def setup_events

    @bot.event.register('irc.message.privmsg',Proc.new{|m|
      next if m.personal
      next unless @bot.command_manager.commands[m.command].nil?
      next if @bot.name == 'fskn_bot' &&
           m.message.slice!(/^;/).nil? # next if ; not prepeneded
      message = "#{m.source.nick}: #{m.message}"
      $event.call('chan.link',[self,message,m])
    })
    
    $event.register('chan.link',Proc.new{|args|
      #
      next if (args.nil? || !args.is_a?(Array))
      (instance,message,m) = args
      next if self == instance
      #
      channels.each do |name,channel|
        say name, message
      end
      #
    })
    
    @bot.event.register('irc.message.join',Proc.new{|m|
      next if m.user.nick == @bot.nick
      message = "#{m.user.nick} has entered #{@bot.server[:host]} #{m.channel}"
      $event.call('chan.link',[self,message])
      
=begin
      next unless @bot.name == 'krocked'
      nick = "gs-" + m.user.nick
      Meth::Bot.new({
        'name' => nick,
        'host' => 'irc.freenode.org',
        'channels' => ["#forsaken"],
        'nick'   => nick,
        'realname' => 'nobody',
        'logger' => {
          'severity' => 'DEBUG',
          'rotate'   => 'daily',
        }
      })
=end
    
    })
    
    @bot.event.register('irc.message.part',Proc.new{|m|
      next if m.user.nick == @bot.nick
      message  = "#{m.user.nick} has left #{@bot.server[:host]} #{m.channel}"
      message += " -- #{m.message}" if m.message
      $event.call('chan.link',[self,message])
    })
    
    @bot.event.register('irc.message.quit',Proc.new{|m|
      next if m.user.nick == @bot.nick
      message  = "#{m.user.nick}: has quit #{@bot.server[:host]} "
      message += " -- #{m.message}" if m.message
      $event.call('chan.link',[self,message])
    })
    
  end
    
end
