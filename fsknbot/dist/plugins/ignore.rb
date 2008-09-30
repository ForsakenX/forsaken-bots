class Ignore < Meth::Plugin
  def pre_init
    @commands = [ :ignore, :unignore, :ignored ]
    @help = {
      :ignore    => "ignore [nick] => Set ignore `[nick]' on.",
      :unignore  => "unignore [nick] => Remove ignore for `[nick]'.",
      :ignored   => "ignored => Returns a list of ignored nicks."
    }
  end
  def post_init
    @db = File.expand_path("#{BOT}/db/ignored.yaml")
    @ignored = (File.exists?(@db) && YAML.load_file(@db)) || []
    @ignored.each do |nick|
      @bot.ignored << nick unless @bot.ignored.include?(nick)
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
    return if m.params.length > 1
    unless nick = m.params.shift
      m.reply help(m)
      return
    end
    if nick =~ /meth/i
      return m.reply "foff"
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
