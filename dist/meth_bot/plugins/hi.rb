class Hi < Meth::Plugin
  def help m
    "hi => Reply's with 'Hey, Whats up!'"
  end
  def command m
    m.reply "Hey, Whats up!"
  end
end
