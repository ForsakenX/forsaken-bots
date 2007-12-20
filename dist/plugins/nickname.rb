class Nickname < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("nickname",self)
    @bot.command_manager.register("nicknames",self)
    @db = "#{DIST}/bots/#{$bot}/db/nicks.yaml"
    @nicks = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
  end
  def help m=nil, topic=nil
    case m.command
    when "nickname"
      "nickname <name> [nickname] => Sets [nickname] for <name>.  "+
      "If [nickname] is omitted then prints a random nickname of <name>."
    when "nicknames"
      "nicknames => Display full list."
    end
  end
  def command m
    case m.command
    when 'nicknames'
      list m
    when 'nickname'
      case m.params[0]
      when "",nil
        random m
      else
        add m
      end
    end
  end
  def add m
    if (nick = m.params.join(' ').chomp) != ""
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
  def random m
    names = @nicks.keys
    name  = names[rand(names.length)]
    m.reply "#{name} => #{@nicks[name]}"
  end
  def list m
    m.reply "No nicknames set!" if @nicks.length < 1
    m.reply @nicks.map{|n,a| "#{n} => #{a.join(', ')}"}.join("; ")
  end
  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@nicks,file)
    file.close
  end
end
