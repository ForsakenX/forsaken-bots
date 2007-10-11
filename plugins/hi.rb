class Hi
  def help m
    "hi => Reply's with 'Hey, Whats up!'"
  end
  def privmsg m
    m.reply "Hey, Whats up!"
  end
end
