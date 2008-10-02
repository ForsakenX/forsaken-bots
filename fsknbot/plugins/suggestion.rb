class Suggestion < Client::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("suggestion",self)
    # storage
    @db = File.expand_path("#{ROOT}/db/suggestions.yaml")
    @suggestions = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def help m=nil, topic=nil
    "suggestion => Display random suggestion.  "+
    "suggestion add [narative] => Add suggestion to the list.  "+
    "suggestion count => Display number of suggestions.  "+
    "suggestion show <index> => Show the n'th suggestion. "+
    "suggestion delete <index> => Delete n'th suggestion. "
  end

  def command m
    @params = m.params
    case @params.shift
    when "",nil
      random m
    when "add"
      add m
    when "show"
      show m
    when "count"
      count m
    when "delete"
      delete m
    else
      m.reply help
    end
  end

  def show m
    index = @params.shift.to_i
    m.reply "#{index}) #{@suggestions[index]}"
  end

  def delete m
    if m.source.nick.downcase != "methods"
      m.reply "You are not authorized to remove suggestions."
      return
    end
    index = @params.shift.to_i
    suggestion = @suggestions.delete_at(index)
    save
    m.reply "removed) #{suggestion}"
    m.reply "new #{index}) #{@suggestions[index]}"
  end

  def count m
    m.reply "There are #{@suggestions.length} suggestions."
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
    message = @params.join(' ')
    # checks
    if message.empty?
      m.reply "Missing [narative].  "+
              "Type help suggestion for more info."
      return
    end
    # save
    @suggestions << message
    save
    m.reply "Suggestion created..."
  end

  def save
    file = File.open(@db,'w+')
    YAML.dump(@suggestions,file)
    file.close
  end

end
