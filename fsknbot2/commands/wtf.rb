
# fuck acroynm just use it as a what

IrcCommandManager.register ['wtf','what'],
"wtf is <acronym> => Translate acronym. "+
"wtf add|set <acronym> <translation> => Add/Change <acryonym> to <translation>  "+
"wtf del|unset <acronym> => Deletes the acronym.  "+
"wtf list => Print list of known acronyms."
  

IrcCommandManager.register ['wtf','what'] do |m|
  m.reply Wtf.run(m)
end

class Wtf < Irc::Plugin
  class << self

    @@db = File.expand_path("#{ROOT}/db/acronyms.yaml")

    def acronyms
      File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
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
      return if m.params.length > 1
      get m
    end
  end
  def list m
    m.reply @acronyms.keys.sort.join(' ')
  end
  def get m
    if m.params.length < 1
      m.reply "Bad usage... Try, 'help wtf'."
      return
    end
    acronym  = m.params.shift.downcase
    unless translation = @acronyms[acronym]
      m.reply "I don't know what #{acronym} is."
      return
    end
    m.reply "#{acronym.upcase}: #{translation}"
  end
  def unset m
    if m.params.length < 1
      m.reply "Bad usage... Try, 'help wtf'."
      return
    end
    acro = m.params.shift
    @acronyms.delete acro
    save
    m.reply "#{acro} has been unset."
  end
  def set m
    if m.params.length < 2
      m.reply "Bad usage... Try, 'help wtf'."
      return
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
