class Nickname < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("nickname",self)
    @bot.command_manager.register("nicknames",self)
    @db = "#{DIST}/bots/#{$bot}/db/nicks.yaml"
    if File.exists?(@db)
      unless @nicks = YAML.load_file(@db)
        @nicks = {}
      end
      @nicks.each do |new,old|
        do_alias(new,old)
      end
    else
      @nicks = {}
    end
  end
  def help m
    case m.command
    when "nickname"
      "nickname <name> [nickname] => Sets [nickname] for <name>.  "+
      "If [nickname] is omitted then prints a random nickname of <name>."
    when "nicknames"
      "nicknames => Display full list."
    end
  end
  def command m
    if m.command == 'nicknames'
      m.reply "No nicknames set!" if @nicks.length < 1
      m.reply @nicks.map{|n,a| "#{n} => #{a.join(', ')}"}.join("; ")
      return
    end
    name = m.params.shift
    m.reply(help(m)) unless name
    if nick = m.params.shift
      @nicks[name.downcase] ?
        @nicks[name.downcase] << nick :
        @nicks[name.downcase] = [nick]
      save
      m.reply "Added #{nick} to #{name}"
    else
      m.reply("#{name} has no nicknames.") unless nicks = @nicks[name.downcase]
      m.reply nicks[rand(nicks.length)]
    end
  end
  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@nicks,file)
    file.close
  end
end
