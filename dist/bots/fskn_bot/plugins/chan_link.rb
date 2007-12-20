class ChanLink < Meth::Plugin

  def initialize *args
    super *args
    setup_events
    if @bot.name == 'fskn_bot'
      $event.register('chan.link',@chanlink_event)
    end
    if @bot.name == 'krocked'
      @bot.event.register('irc.message.privmsg',@privmsg_event)
      @bot.event.register('irc.message.join',@join_event)
      @bot.event.register('irc.message.part',@part_event)
      @bot.event.register('irc.message.quit',@quit_event)
      @bot.event.register('irc.message.kick',@kick_event)
    end
  end

  def cleanup *args
    super *args
    if @bot.name == 'fskn_bot'
      $event.unregister('chan.link',@chanlink_event)
    end
    if @bot.name == 'krocked'
      @bot.event.unregister('irc.message.privmsg',@privmsg_event)
      @bot.event.unregister('irc.message.join',@join_event)
      @bot.event.unregister('irc.message.part',@part_event)
      @bot.event.unregister('irc.message.quit',@quit_event)
      @bot.event.unregister('irc.message.kick',@kick_event)
    end
  end

  def setup_events

    @chanlink_event = Proc.new{|args|
      # check args
      next if (args.nil? || !args.is_a?(Array))
      # rename args
      (instance,message,m) = args
      # dont send to same server
      next if self == instance
      # send to all channels
      @bot.channels.keys.each do |channel|
        # mirror messages to other channel
        @bot.say(channel, message)
      end
    }
    
    # Copy message between channels
    @privmsg_event = Proc.new{|m|
      message = m.message
      output = "#{m.source.nick}: #{message}"
      $event.call('chan.link',[self,output,m])
    }

    # copy join events
    @join_event = Proc.new{|m|
      message = "#{m.user.nick} has joined #{@bot.server[:host]} #{m.channel}"
      $event.call('chan.link',[self,message])
    }
    
    @part_event = Proc.new{|m|
      message  = "#{m.user.nick} has parted #{@bot.server[:host]} #{m.channel}"
      message += " -- #{m.message}" if m.message.length > 0
      $event.call('chan.link',[self,message])
    }
    
    @quit_event = Proc.new{|m|
      message  = "#{m.user.nick} has quit #{@bot.server[:host]}"
      message += " -- #{m.message}" if m.message.length > 0
      $event.call('chan.link',[self,message])
    }

    @kick_event = Proc.new{|m|
      message  = "#{m.admin.nick} kicked "
      message += "#{m.user.nick} from "
      message += "#{@bot.server[:host]} "
      message += " -- #{m.message}" if m.message.length > 0
      $event.call('chan.link',[self,message])
    }
             
  end
    
end
