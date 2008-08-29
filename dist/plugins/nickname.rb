class Nickname < Meth::Plugin
  def pre_init
    @commands = [:nickname]
    @db = "#{BOT}/db/nicks.yaml"
    @nicks = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
  end
  def help m=nil, topic=nil
    "nickname add <name> [nickname] => Sets [nickname] for <name>.  "+
    "nickname show <name> => Show nicknames for <name>.  "+
    "nickname => Show random nick names...  "+
    "nicknames => Display full list."
  end
  def nickname m
    @params = m.params.dup
    case @params.shift.downcase
    when "add"
      add m
    when "show"
      show m
    when "list"
      list m
    else
      random m
    end
  end
  def show m
    unless name = @params.shift.downcase
      m.reply "Missing name!"
      return false
    end
    unless nicks = @nicks[name]
      m.reply "No nicknames for #{name}"
      return false
    end
    m.reply "#{name} => " + nicks.join('; ')
  end
  def add m
    unless name = @params.shift.downcase
      m.reply "Missing name!"
      return false
    end
    if (nick = @params.join(' ').chomp).empty?
      m.reply "Missing nick name !"
      return false
    end
    @nicks[name] ?
      @nicks[name] << nick :
      @nicks[name] = [nick]
    save
    m.reply "Added #{nick} to #{name}"
  end
  def random m
    names = @nicks.keys
    name  = names[rand(names.length)]
    m.reply "#{name} => #{@nicks[name]}"
  end
  def list m
    if @nicks.length < 1
      m.reply "No nicknames set!"
      return false
    end
    m.reply "A list of nicknames has been messaged to you!"
    m.reply_directly @nicks.map{|n,a| "#{n} => #{a.join(', ')}"}.join("; ")
  end
  def save
    file = File.open(@db,'w+')
    YAML.dump(@nicks,file)
    file.close
  end
end
