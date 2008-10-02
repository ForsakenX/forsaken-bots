class PrivmsgCopier < Client::Plugin
  def privmsg m
    return unless m.personal
    return if m.source.nick.downcase == "methods"
    @bot.msg "methods", "#{m.source.nick} => #{m.message}"
  end
end
