class Ignore < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("ignore",self)
    @bot.command_manager.register("unignore",self)
    @bot.command_manager.register("ignored",self)
    @db = File.expand_path("#{DIST}/bots/#{$bot}/db/ignored.yaml")
    @ignored = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
    @ignored.each do |nick|
      @bot.ignored << nick unless @bot.ignored.include?(nick)
    end
  end
  def help(m=nil, topic=nil)
    "ignore [nick] => Add [nick] to my ignore list..."
  end
  def command m
    case m.command
    when "ignored"
      ignored m
    when "ignore"
      ignore m
    when "unignore"
      unignore m
    end
  end
  def unignore m
    nick = m.params.shift.downcase
    unless @bot.ignored.include?(nick) && @ignored.include?(nick)
      m.reply "#{nick} was not on the list..."
      return
    end
    @ignored.delete nick
    @bot.ignored.delete nick
    save
    m.reply "#{nick} removed from ignore list."
  end
  def ignored m
    if m.command == 'ignored'
      if @bot.ignored.length < 1
        m.reply "No users ignored..."
      else
        m.reply @bot.ignored.join(", ")
      end
      return
    end
  end
  def ignore m
    unless nick = m.params.shift
      m.reply help(m)
      return
    end
    if @bot.ignored.include?(nick) && @ignored.include?(nick)
      m.reply "#{nick} is allready ignored..."
      return
    end
    @bot.ignored << nick.downcase
    @ignored << nick.downcase
    save
    m.reply "Nick, '#{nick}' added to ignore list..."
  end
  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@ignored,file)
    file.close
  end
end
