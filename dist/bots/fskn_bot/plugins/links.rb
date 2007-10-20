class Links < LinksPlugin
  def help m=nil
    "links <name> => "+
    "Display url for <name>.  "+
    "If <name> is ommitted displays entire list."
  end
  def command m
    if name = m.params.shift
      m.reply links[name]
    else
      list m
    end
  end
  def list m
    output = []
    links.each do |name,url|
      output << "#{name} => #{url}"
    end
    m.reply "Links (#{links.length}): #{output.join(', ')}"
  end
end
