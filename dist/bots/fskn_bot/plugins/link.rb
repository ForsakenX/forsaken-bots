class Link < LinksPlugin
  def help
    m.reply "link add <name> <url> => Adds a link to the list.  "+
            "link delete <name> => Removes a link.  "+
            "Typing a or d is sufficient."
  end
  def command m
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
