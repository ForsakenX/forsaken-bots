class Quote < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("quote",self)
    # storage
    @db = File.expand_path("#{BOT}/db/quotes.yaml")
    @quotes = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end

  def help m=nil, topic=nil
    "quote add <narative> => Add a quote to the list.  "+
    "quote show <id> => Show quote by <id>. "+
    "quote search <needle> => Search quotes for <needle>.  "+
    "quote [random] [needle] => Display random quote, "+
           "optionally within range of [needle]."
  end

  def command m
    @params = m.params.dup
    case @params.shift
    when "random","",nil
      random m
    when "add"
      add m
    when "search"
      search m
    when "show"
      show m
    end
  end

  def show m
    if (index = @params.shift).nil? || (index =~ /^[^0-9]+$/)
      m.reply "Bad value given for index.  "+help(m,:show)
      return
    end
    m.reply @quotes[index.to_i]
  end

  def search m
    needle = @params.shift
    found  = []
    @quotes.each_with_index {|quote,i|
      return unless quote.include?(needle)
      found << i
    }
    m.reply "Found #{found.length} that matched: #{found.join(', ')}"
  end

  def random m
    # none
    if @quotes.length < 1
      m.reply "There are no quotes yet..."
      return
    end
    # default all quotes
    quotes = @quotes
    # search string given
    unless (needle = @params.shift).nil?
      quotes = @quotes.find_all{|quote| quote.include?(needle)}
    end
    # none
    if quotes.length < 1
      m.reply "There are no quotes that match your search..."
      return
    end
    # random
    m.reply quotes[rand(quotes.length)]
  end

  def add m
    # narative
    message = @params.join(' ')
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
