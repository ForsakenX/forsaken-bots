class Advice < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("advice",self)
    # storage
    @db = File.expand_path("#{DIST}/bots/#{$bot}/db/advices.yaml")
    @advices = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def help m=nil, topic=nil
    "advice => Display random advice.  "+
    "advice add [narative] => Add advice to the list."
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
    if @advices.length < 1
      m.reply "There are no advices..."
      return
    end
    # random
    m.reply @advices[rand(@advices.length)]
  end

  def add m
    # narative
    message = m.params.join(' ')
    # checks
    if message == ""
      m.reply "Missing [narative].  "+
              "Type help advice for more info."
      return
    end
    # save
    @advices << message
    save
    m.reply "Advice created..."
  end

  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@advices,file)
    file.close
  end

end
