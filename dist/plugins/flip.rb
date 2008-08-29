class Flip < Meth::Plugin

  def pre_init
    @bot.command_manager.register("flip",self)
    @sides = %w{ heads tails }
  end

  def help m=nil, topic=nil
    "flip => Flips a coin."
  end

  def command m
    m.reply flip
  end

  def flip
    side = (File.new('/dev/urandom').read(9)[0] % 2) == 0 ? 1 : 0
    @sides[ side ]
  end

end
