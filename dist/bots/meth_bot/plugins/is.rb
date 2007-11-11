class Is < Meth::Plugin
  @@db = { 'food' => ['something you eat'] }
  def initialize *args
    super *args
    @bot.command_manager.register("learned",self)
    @p = Proc.new{|m| privmsg m}
    @bot.event.register('irc.message.privmsg',@p)
  end
  def cleanup *args
    super *args
    @bot.event.unregister('irc.message.privmsg',@p)
  end
  def help m
    "learned => list learned associations."
  end
  def command m
    learned m
  end
  def learned m
    m.reply @@db.map{|w,list| list.uniq!; "#{w} is #{list.join(', or ')}"}.join("; ")
  end
  def learn m
    message = m.message
    while message.slice!(/([^ ]+) +is +([^ ]+)/i)
      (target,desc) = [$1.downcase,$2]
      next if target == 'what'
      puts "[INFO] Learned #{target} is #{desc}"
      @@db[target] = [] unless @@db[target]
      @@db[target] << desc
    end
  end
  def what m
    message = m.message
    while message.slice!(/what +is +([^ ]+)/i)
      next unless @@db[$1.downcase]
      @@db[$1.downcase].uniq!
      targets = @@db[$1.downcase]
      m.reply targets[rand(targets.length)]
    end
  end
  def privmsg m
    what  m
    learn m
  end
end
