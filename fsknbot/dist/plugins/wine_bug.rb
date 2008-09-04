class WineBug < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("winebug",self)
    # storage
    @db = File.expand_path("#{BOT}/db/wine_bugs.yaml")
    @wine_bugs = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
    @url = "http://fly.thruhere.net/wine/bugs.txt"
  end

  def help m=nil, topic=nil
    "winebug => Display random winebug.  "+
    "winebug add [narative] => Add winebug to the list.  "+
    "winebug count => Display number of winebugs.  "+
    "winebug show <index> => Show the n'th winebug. "+
    "winebug delete <index> => Delete n'th winebug. "+
    "winebug url => Url for the wine bug list."
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
    when "url"
      url m
    else
      m.reply help
    end
  end

  def url m
    m.reply "wine bug list: #{@url}"
  end

  def show m
    index = @params.shift.to_i-1
    m.reply "#{index}) #{@wine_bugs[index]}"
  end

  def delete m
    admins = ["methods","frostbite4"]
    unless admins.include?(m.source.nick.downcase)
      m.reply "Only #{admin.join(', ')} can delete entries"
      return
    end
    index = @params.shift.to_i-1
    wine_bug = @wine_bugs.delete_at(index)
    save
    m.reply "removed) #{wine_bug}"
    m.reply "new #{index}) #{@wine_bugs[index]}"
  end

  def count m
    m.reply "There are #{@wine_bugs.length} wine_bugs."
  end

  def random m
    # none
    if @wine_bugs.length < 1
      m.reply "There are no wine_bugs..."
      return
    end
    # random
    m.reply @wine_bugs[rand(@wine_bugs.length)]
  end

  def add m
    # narative
    message = @params.join(' ')
    # checks
    if message.empty?
      m.reply "Missing [narative].  "+
              "Type help wine_bug for more info."
      return
    end
    # save
    @wine_bugs << message
    save
    m.reply "WineBug created..."
  end

  def save
    file = File.open(@db,'w+')
    YAML.dump(@wine_bugs,file)
    file.close
  end

end
