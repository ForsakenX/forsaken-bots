require 'yaml'
class LinksPlugin < Meth::Plugin
  def initialize *args
    super *args
    @db = "#{DIST}/" +  @bot.config['plugins_path'] + "/links.yaml"
  end
  def links
    data = YAML.load_file(@db) if File.exists?(@db)
    puts "links #{data}"
    data ? data : {}
  end
  def delete name
    data = links
    data[name] = nil
    save data
  end
  def save data
    puts "save #{data}"
    YAML.dump(data,File.open(@db,'w+'))
  end
  def add(name, url)
    data = links
    data[name] = url
    save data
  end
end
