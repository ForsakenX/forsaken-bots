class Links < LinksPlugin
  def initialize *args
    super *args
    @bot.command_manager.register("links",self)
    @bot.command_manager.register("link",self)
  end
  def help m=nil
    case m.params[0]
    when "links"
      "links <name> => "+
      "Display url for <name>.  "+
      "If <name> is ommitted displays entire list."
    when "link"
      "link add <name> <url> => "+
      "Adds a link to the list.  "+
      "link delete <name> => Removes a link.  "+
      "Typing the first letter of add/delete is sufficient."
    end
  end
  def command m
    case m.command
    when "links"
      links m
    when "link"
      link m
    end
  end
  def links m
    if name = m.params.shift
      m.reply links[name]
    else
      list m
    end
  end
  def list m
    output = []
    links.sort.each do |x|
      (name,url) = x
      output << "#{name}: #{url}"
    end
    m.reply "Links (#{links.length}): #{output.join(', ')}"
  end
  def link m
    (switch,name,url) = m.params
    case switch
    when /^a/
      if m.params.length < 2
        m.reply "Missing <name> <url>.  Type 'help link' for more information."
        return
      end
      add(name,url)
      m.reply "Added #{name} => #{url}"
    when /^d/
      delete name
      m.reply "Deleted #{name}"
    else
      m.reply "Unrecognized action.  Type 'help link' for more information."
    end
  end
end
