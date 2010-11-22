
IrcChatMsg.register do |m|

  max = 512 - 2 # 512 - \r\n parsed by receive line

  # detect possible overflow
  next unless m.line.length >= max

  # show end of message
  length = 120  # length of message to show
  last_part = m.line[(max-1-length)..(max-1)]

  m.reply "Your message has possibly been cut off.  "+
          "The last #{length} characters where::: "+
          "#{last_part}"

end

