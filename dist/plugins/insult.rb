class Insult < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("insult",self)
    # storage
    @db = File.expand_path("#{BOT}/db/insults.yaml")
    @insults = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def help m=nil, topic=nil
    "insult => Display random insult.  "+
    "insult add [narative] => Add insult to the list."
  end

  def command m
    case m.params.shift
    when "",nil
      random m
    when "add"
      add m
    else
      m.reply help
    end
  end

  def random m
    # none
    if @insults.length < 1
      m.reply "There are no insults..."
      return
    end
    # random
    m.reply @insults[rand(@insults.length)]
  end

  def add m
    # narative
    message = m.params.join(' ')
    # checks
    if message == ""
      m.reply "Missing [narative].  "+
              "Type help insult for more info."
      return
    end
    # save
    @insults << message
    save
    m.reply "Insult created..."
  end

  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@insults,file)
    file.close
  end

end
