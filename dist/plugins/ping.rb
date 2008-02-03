class Ping < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("ping",self)
    @db = File.expand_path("#{DIST}/bots/#{$bot}/db/ping_blocked.yaml")
    @blocked = (FileTest.exists?(@db) && YAML.load_file(@db)) || []
  end
  def help(m=nil, topic=nil)
    "ping => Writes everyones name on one line.  "+
    "Normally their client will produce a notification.  "+
    "ping block => Blocks your name from showing up on a ping event.  "+
    "ping unblock => Removes your name from the block list."
  end
  def command m
    case m.params.shift
    when "block"
      block m
    when "unblock"
      unblock m
    else
      ping m
    end
  end
  def block m
    @blocked << m.source.nick.downcase unless @blocked.index(m.source.nick.downcase)
    save
    m.reply "You have been blocked"
  end
  def unblock m
    @blocked.delete(m.source.nick.downcase)
    save
    m.reply "You have been unblocked."
  end
  def ping m
    users = m.channel.users.map{ |user| user.nick.downcase }
    @blocked.each { |user| users.delete(user) }
    m.reply users.join(' ')
  end
  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@blocked,file)
    file.close
  end
end
