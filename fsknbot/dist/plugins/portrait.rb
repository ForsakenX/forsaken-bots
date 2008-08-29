class Portrait < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("portrait",self)
    @bot.command_manager.register("portraits",self)
    @db = "#{BOT}/db/portraits.yaml"
    @portraits = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
  end
  def help m=nil, topic=nil
    "portrait <name> [link] => Sets portrait [link] for <name>.  "+
    "If [link] is omitted then displays a random nickname of <name>."
  end
  def command m
    if m.command == 'portraits'
      message = "http://home.comcast.net/~wlm00/forsaken_characters.htm  -  "+
                @portraits.map{|k,v| "#{k} => #{v}"}.join(', ')
      m.reply message
      return
    end
    name = m.params.shift
    m.reply(help(m)) unless name
    if link = m.params.shift
      @portraits[name.downcase] ?
        @portraits[name.downcase] << link :
        @portraits[name.downcase] = [link]
      save
      m.reply "Added #{link} to #{name}"
    else
      m.reply("#{name} has no portraits.") unless portraits = @portraits[name.downcase]
      m.reply portraits[rand(portraits.length)]
    end
  end
  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@portraits,file)
    file.close
  end
end
