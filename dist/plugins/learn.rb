class Learn < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("learn",self)
    @bot.command_manager.register("learned",self)
    @bot.command_manager.register("unlearn",self)
    @bot.command_manager.register("what",self)
    @db = File.expand_path("#{DIST}/bots/#{$bot}/db/associations.yaml")
    @associations = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
  end
  def help(m=nil, topic=nil)
    "learn <something> is <description> => Learn something.  "+
    "unlearn <something> => Unlearn it.  "+
    "what is <something> => Show <description> for <something>.  "+
    "TIPS:  "+
    "<something> is a single word.  "+
    "<description> can be multi word."
  end
  def command m
    case m.command
    when "learn"
      learn m
    when "unlearn"
      unlearn m
    when "what"
      what m
    when "learned"
      learned m
    end
  end
  def learn m
    what = m.params.shift
    return false unless m.params.shift == "is"
    description = m.params.join(' ')
    @associations[what.downcase] = description
    save
    m.reply "Done."
  end
  def unlearn m
    return false if m.params.length > 1
    what = m.params.shift
    @associations.delete what.downcase
    save
    m.reply "Done."
  end
  def what m
    return false unless m.params.shift == "is"
    target = m.params.shift
    return false if m.params.length > 0
    unless target
      m.reply "What is what?"
      return false
    end
    if association = @associations[target.downcase]
      m.reply "#{target} is #{association}"
    else
      m.reply "I don't know what #{target} is."
    end
  end
  def learned m
    return false if m.params.length > 0
    m.reply "#{@associations.length} associations: "+
            @associations.keys.sort.join(', ')
  end
  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@associations,file)
    file.close
  end
end
