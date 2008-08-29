class Broadcast < Meth::Plugin
  def pre_init
    @commands = [:broadcast]
    @db = File.expand_path("#{BOT}/db/broadcasts.yaml")
    @broadcasts = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
  end
  def help m=nil, topic=nil
    "broadcast => Says a random message to the channel.  "+
    "broadcast add <message> => Add message to the list.  "+
    "Random messages go off randomly..."
  end
  def broadcast m
    @params = m.params
    case @params.shift
    when "add"
      add m
    else
      random m
    end
  end
  def add m
    message = @params.join(' ')
    broadcast = {
      :user => m.user.nick.downcase,
      :message => message
    }
    m.reply "Done."
  end
  def random m
    broadcast = @broadcasts[rand(@broadcasts.length)]
    m.reply broadcast[:message]
  end
  def save
    file = File.open(@db,'w+')
    YAML.dump(@broadcasts,file)
    file.close
  end
end
