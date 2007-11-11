class Nickname < Meth::Plugin
  @@nicks = {
  #  :name => [ 1, 2, 3 ]
  }
  def initialize *args
    super *args
    @bot.command_manager.register("nickname",self)
  end
  def help m
    "nickname <name> [nickname] => Sets [nickname] for <name>.  "+
    "If [nickname] is omitted then prints a random nickname of <name>."
  end
  def command m
    name = m.params.shift
    m.reply(help(m)) unless name
    if nick = m.params.shift
      @@nicks[name.downcase] ?
        @@nicks[name.downcase] << nick :
        @@nicks[name.downcase] = [nick]
      m.reply "Added #{nick} to #{name}"
    else
      m.reply("#{name} has no nicknames.") unless nicks = @@nicks[name.downcase]
      m.reply nicks[rand(nicks.length)]
    end
  end
end
