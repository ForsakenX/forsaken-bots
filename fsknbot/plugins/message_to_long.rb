class MessageToLong < Client::Plugin
  def privmsg m
    # 512 - \r\n parsed by receive line
    max = 512 - 2
    # detect possible overflow
    return unless m.line.length >= max
    # length of message to show
    length = 120
    # cut off end of message
    last_part = m.line[(max-1-length)..(max-1)]
    # notify them
    m.reply_notice "Your message has been cut off.  "+
                   "The last #{length} characters where: "+
                   "\"#{last_part}\""
  end
  alias_method :notice, :privmsg
end
