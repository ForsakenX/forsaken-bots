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
        m.reply "#{$!} : #{$@.join(' : ')}"
      end
    end
  end
  def help m
    m.reply "Admin Commands: msg"
  end
  def msg m
    target = @params.shift
    message = @params.join(' ')
    @bot.msg target, message
  end
end
