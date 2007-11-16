class Plot < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("plot",self)
    # storage
    @db = File.expand_path("#{DIST}/bots/#{$bot}/db/plots.yaml")
    @plots = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def help m=nil, topic=nil
    "plot => Display random plot.  "+
    "plot add [narative] => Add a plot to the list."
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
    if @plots.length < 1
      m.reply "There are no plots..."
      return
    end
    # random
    m.reply @plots[rand(@plots.length)]
  end

  def add m
    # narative
    message = m.params.join(' ')
    # checks
    if message == ""
      m.reply "Missing [narative].  "+
              "Type help plot for more info."
      return
    end
    # save
    @plots << message
    save
    m.reply "Plot created..."
  end

  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@plots,file)
    file.close
  end

end
