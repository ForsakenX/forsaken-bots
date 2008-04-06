class Admin < Meth::Plugin
  def pre_init
    @admin_callback = Proc.new{|m|admin(m)}
    @bot.event.register('meth.command.admin',@admin_callback)
  end
  def cleanup *args
    super *args
    @bot.event.unregister('meth.command.admin',@admin_callback)
  end
  def admin m
    return unless m.source.nick.downcase == "methods"
    @params = m.params
    case @params.shift
    when "help"
      help m
    when "msg"
      msg m
    when "raw"
      @bot.send_data "#{@params.join(' ')}\n"
    when "!"
      begin
        eval(@params.join(' '))
      rescue Exception
        m.reply "#{$!}"# : #{$@.join(' : ')}"
      end
    when "chan_setup"
      chan_setup m
    end
  end
  def help m
    m.reply "Admin Commands: help,msg,!,raw,chan_setup"
  end
  def msg m
    target = @params.shift
    message = @params.join(' ')
    @bot.msg target, message
  end
  def chan_setup m
    # make sure channel is not setup
    # and the bot is an admin in the room
    
    # vars
    params = m.params
    channel = params.shift

    # send to chanserv
    
    masters = %w{fsknbot}
    masters.each do |master|
      @bot.msg "ChanServ","access #{channel} add #{master} 49"
    end
    
    boyscouts = %w{silence DIII-The_Lion methods}
    boyscouts.each do |boyscout|
      @bot.msg "ChanServ","access #{channel} add #{boyscout} 13"
    end
    
    access_rights = { "*!*@*" => 3 }
    access_rights.each do |mask,level|
      @bot.msg "ChanServ","access #{channel} add #{mask} #{level}"
    end
    
    levels = { 11 => 44, 7 => 13, 8 => 13,
               8  => 13, 6 => 40, 4 => 46,
               2  => 3 }
    levels.each do |index,level|
      @bot.msg "ChanServ", "level #{channel} set #{index} #{level}"
    end
    
    sets = { "password" => password,
             "gaurd"    => "on" }
    sets.each do |key,val|
      @bot.msg "ChanServ", "set #{channel} #{key} #{val}"
    end
    
    # send to new channel
    topic = "Welcome "
    user_message = "Replace me ! Type help topic"
    @bot.send_data "topic #{channel} :#{topic} || #{user_message}\n"
  end
end


