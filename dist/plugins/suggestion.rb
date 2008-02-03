class Suggestion < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("suggestion",self)
    # storage
    @db = File.expand_path("#{BOT}/db/suggestions.yaml")
    @suggestions = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def help m=nil, topic=nil
    "suggestion => Display random suggestion.  "+
    "suggestion add [narative] => Add suggestion to the list."
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
    if @suggestions.length < 1
      m.reply "There are no suggestions..."
      return
    end
    # random
    m.reply @suggestions[rand(@suggestions.length)]
  end

  def add m
    # narative
    message = m.params.join(' ')
    # checks
    if message == ""
      m.reply "Missing [narative].  "+
              "Type help suggestion for more info."
      return
    end
    # save
    @suggestions << message
    save
    m.reply "Suggestion created..."
  end

  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@suggestions,file)
    file.close
  end

end
