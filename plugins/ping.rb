class Ping
  def help m
    "ping => Reply's with 'pong'"
  end
  def privmsg m
    m.reply "pong"
  end
end
