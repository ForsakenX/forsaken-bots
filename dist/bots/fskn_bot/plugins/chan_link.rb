class ChanLink < Meth::Plugin

  def initialize *args
    super *args
    if @bot.name != 'fskn_bot_games'
      setup_events
      register_events
    end
  end

  def cleanup *args
    super *args
    unregister_events
  end

  def register_events
    $event.register('chan.link',@chanlink_event)
    @bot.event.register('irc.message.privmsg',@privmsg_event)
    @bot.event.register('irc.message.join',@join_event)
    @bot.event.register('irc.message.part',@part_event)
    @bot.event.register('irc.message.quit',@quit_event)
    @bot.event.register('irc.message.kick',@kick_event)
  end

  def unregister_events
    $event.unregister('chan.link',@chanlink_event)
    @bot.event.unregister('irc.message.privmsg',@privmsg_event)
    @bot.event.unregister('irc.message.join',@join_event)
    @bot.event.unregister('irc.message.part',@part_event)
    @bot.event.unregister('irc.message.quit',@quit_event)
    @bot.event.unregister('irc.message.kick',@kick_event)
  end

  def setup_events

    @chanlink_event = Proc.new{|args|
      # check args
      next if (args.nil? || !args.is_a?(Array))
      # rename args
      (instance,message,m) = args
      # sending to gamespy requires semi colon to send
      next if m.class.name == 'PrivMessage' &&
              @bot.name    == 'krocked'     &&
              message.slice!(/^;/).nil?
      # send to all channels
      @bot.channels.keys.each do |channel|

        # dont send to same server
        next if self == instance

        # mirror messages to other channel
        @bot.say(channel, message)

      end
    }
    
    # Copy message between channels
    @privmsg_event = Proc.new{|m|
      next if m.personal
      next unless @bot.command_manager.commands[m.command].nil?
      output = "#{m.source.nick}: #{m.message}"
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

