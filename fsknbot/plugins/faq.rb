require 'yaml'
class Faq < Meth::Plugin
  def initialize *args
    super *args
    @db = "#{ROOT}/db/faq.yaml"
    @bot.command_manager.register("faq",self)
    @faq = (FileTest.exists?(@db) && YAML.load_file(@db)) || {}
  end
  def help m=nil, topic=nil
    h={
    :list   => "faq [list] => List all faq names.  ",
    :get    => "faq [get] <name> => Show the faq for <name>.  ",
    :set    => "faq set|add <name> <answer> => Adds a faq to the list.  ",
    :del    => "faq del <name> => Removes a faq.  "
    }
    h_aliases = {:add => :set}
    unless topic.nil? && topic.responds_to?(:to_sym)
      return _alias unless (_alias = h[h_aliases[topic.to_sym]]).nil?
      return _topic unless (_topic = h[topic.to_sym]).nil?
    end
    return [:list,:get,:set,:del,:change,:notes].map{|key|h[key]}.join(', ')
  end
  def command m
    switch = m.params.shift
    case switch
    when "",nil,"list"
      list m
    when "set","add"
      set m
    when "del"
      del m
    when "get"
      get m, m.params.shift
    else
      get m, switch
    end
  end
  def list m
    if @faq.keys.empty?
      m.reply "There are no faq's yet."
      return
    end
    m.reply "A list of faq's has been messaged to you."
    m.reply_directly @faq.keys.sort.join(', ')
  end
  def get m, name
    if name.nil?
      m.reply "Missing <name>.  "+help(m,:get)
      return
    end
    unless @faq[name]
      m.reply "faq `#{name}' does not exist."
      return
    end
    m.reply @faq[name]
  end
  def set m
    unless name = m.params.shift
      m.reply "Missing <name>. "+help(m,:set)
      return
    end
    unless answer = m.params.join(' ')
      m.reply "Missing <answer>.  "+help(m,:set)
      return
    end
    @faq[name] = answer
    save
    m.reply "Done."
  end
  def del m
    unless name = m.params.shift
      m.reply "Missing <name>.  "+help(m,:del)
      return
    end
    if @faq[name].nil?
      m.reply "faq `#{name}' does not exist."
      return
    end
    @faq.delete name
    save
    m.reply "Done."
  end
  private
  def save
    f = File.open(@db,'w+')
    YAML.dump(@faq,f)
    f.close
  end
end
