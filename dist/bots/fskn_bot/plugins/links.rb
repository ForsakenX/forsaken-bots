require 'yaml'
class Links < Meth::Plugin
  def initialize *args
    super *args
    @db = "#{DIST}/bots/#{$bot}/db/links.yaml"
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
      cmd_links m
    when "link"
      cmd_link m
    end
  end
  def cmd_links m
    if name = m.params.shift
      m.reply links[name]
    else
      output = []
      links.sort.each do |x|
        (name,url) = x
        output << "#{name}"#: #{url}"
      end
      m.reply "Links (#{links.length}): #{output.join(', ')}"
    end
  end
  def cmd_link m
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
  private
  def links
    data = YAML.load_file(@db) if File.exists?(@db)
    data ? data : {}
  end
  def delete name
    data = links
    data.delete(name)
    save data
  end
  def save data
    f = File.open(@db,'w+')
    YAML.dump(data,f)
    f.close
  end
  def add(name, url)
    data = links
    data[name] = url
    save data
  end
end
