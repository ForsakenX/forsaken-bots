class Admin < Meth::Plugin
  def privmsg m
    return unless m.personal
    return unless m.source.nick.downcase == "methods"
    admin(m) if m.command == "admin"
  end
  def admin m
    @params = m.params
    case @params.shift
    when "help"
      help m
    when "msg"
      msg m
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
