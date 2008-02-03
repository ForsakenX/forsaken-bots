class Quote < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("quote",self)
    # storage
    @db = File.expand_path("#{BOT}/db/quotes.yaml")
    @quotes = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def help m=nil, topic=nil
    "quote => Display random quote.  "+
    "quote add [narative] => Add a quote to the list."
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
    if @quotes.length < 1
      m.reply "There are no quotes..."
      return
    end
    # random
    m.reply @quotes[rand(@quotes.length)]
  end

  def add m
    # narative
    message = m.params.join(' ')
    # checks
    if message == ""
      m.reply "Missing [narative].  "+
              "Type help quote for more info."
      return
    end
    # save
    @quotes << message
    save
    m.reply "Quote created..."
  end

  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@quotes,file)
    file.close
  end

end
