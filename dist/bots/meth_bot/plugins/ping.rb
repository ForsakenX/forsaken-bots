class Ping < Meth::Plugin
  def help m
    "ping => Reply's with 'pong'"
  end
  def command m
    m.reply "pong"
  end
end
