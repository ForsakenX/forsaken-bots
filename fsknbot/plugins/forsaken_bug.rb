class ForsakenBug < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("forsakenbug",self)
    # storage
    @db = File.expand_path("#{BOT}/db/forsaken_bugs.yaml")
    @forsaken_bugs = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
    @url = "http://chino.homelinux.org/~daquino/forsaken/forsaken_bugs.yaml"
  end

  def help m=nil, topic=nil
    "forsakenbug => Display random forsakenbug.  "+
    "forsakenbug add [narative] => Add forsakenbug to the list.  "+
    "forsakenbug count => Display number of forsakenbugs.  "+
    "forsakenbug show <index> => Show the n'th forsakenbug. "+
    "forsakenbug delete <index> => Delete n'th forsakenbug. "+
    "forsakenbug url => Url for the wine bug list."
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
    m.reply "#{index}) #{@forsaken_bugs[index]}"
  end

  def delete m
    admins = ["methods","frostbite4"]
    unless admins.include?(m.source.nick.downcase)
      m.reply "Only #{admin.join(', ')} can delete entries"
      return
    end
    index = @params.shift.to_i-1
    forsaken_bug = @forsaken_bugs.delete_at(index)
    save
    m.reply "removed) #{forsaken_bug}"
    m.reply "new #{index}) #{@forsaken_bugs[index]}"
  end

  def count m
    m.reply "There are #{@forsaken_bugs.length} forsaken_bugs."
  end

  def random m
    # none
    if @forsaken_bugs.length < 1
      m.reply "There are no forsaken_bugs..."
      return
    end
    # random
    m.reply @forsaken_bugs[rand(@forsaken_bugs.length)]
  end

  def add m
    # narative
    message = @params.join(' ')
    # checks
    if message.empty?
      m.reply "Missing [narative].  "+
              "Type help forsaken_bug for more info."
      return
    end
    # save
    @forsaken_bugs << message
    save
    m.reply "ForsakenBug created..."
  end

  def save
    file = File.open(@db,'w+')
    YAML.dump(@forsaken_bugs,file)
    file.close
  end

end
