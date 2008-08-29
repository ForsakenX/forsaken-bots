class NickProtection < Meth::Plugin
  def pre_init
    @commands = [:protect]
    @db = File.expand_path("#{BOT}/db/nick_protection.yaml")
    @users = File.exists?(@db) ? YAML.load_file(@db) : {}
    @bot.timer.add(5.minutes){ check_users }
    @logs = {}
  end
  def help m=nil, topic=nil
    "protect [password] => "+
    "Periodically checks if your nick is online and registered.  "+
    "Other wise it will ghost the user off of your nick to protect it..."
  end
  def protect m
    user = m.source.nick.downcase
    if @users[user]
      m.reply "You are already protected..."
      return false
    end
    params = m.params.dup
    pass = params.shift
    @users[user] = { :pass => pass }
    save
    m.reply "You have been added to the list..."
  end
  def check_users
    @users.each do |user|
      next if !is_online(user)
      next if is_identified(user)
      next if is_before_time(user)
      ghost(user)
    end
  end
  def ghost user
    @bot.msg "nickserv", "ghost #{user} #{@users[user][:pass]}"
  end
  def is_before_time user
    (Time.now - @logs[user][:online]) < 5.minutes
  end
  def is_online user
  end
  def is_identified user
  end
  def save
    file = File.open(@db,'w+')
    YAML.dump(@users,file)
    file.close
  end
end
