class Wtf < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("wtf",self)
    @db = File.expand_path("#{BOT}/db/acronyms.yaml")
    @acronyms = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
  end
  def help(m=nil, topic=nil)
    "wtf is <acronym> => Translate acronyms.  "+
    "wtf add|set <acronym> <translation> => Add/Change <acryonym> to <translation>.  "+
    "wtf del|unset <acronym> => Deletes the acronym.  "+
    "wtf list => Print list of known acronyms."
  end
  def command m
    case switch = m.params.shift
    when /list/i
      list m
    when /(set|add)/i
      set m
    when /(unset|del)/i
      unset m
    when /is/i
      next if m.params.length > 1
      get m
    end
  end
  def list m
    m.reply @acronyms.keys.sort.join(' ')
  end
  def get m
    if m.params.length < 1
      m.reply "Bad usage... Try, 'help wtf'."
      next
    end
    acronym  = m.params.shift
    unless translation = @acronyms[acronym]
      m.reply "I don't know what #{acronym} is."
      next
    end
    m.reply "#{acronym}: #{translation}"
  end
  def unset m
    if m.params.length < 1
      m.reply "Bad usage... Try, 'help wtf'."
      next
    end
    acro = m.params.shift
    @acronyms.delete acro
    save
    m.reply "#{acro} has been unset."
  end
  def set m
    if m.params.length < 2
      m.reply "Bad usage... Try, 'help wtf'."
      next
    end
    acronym = m.params.shift.downcase
    translation = m.params.join(' ')
    @acronyms[acronym] = translation
    save
    m.reply "Done."
  end
  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@acronyms,file)
    file.close
  end
end
