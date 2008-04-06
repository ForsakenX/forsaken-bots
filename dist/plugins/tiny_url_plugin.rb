require 'tinyurl'
class TinyUrlPlugin < Meth::Plugin
  def pre_init
    @bot.command_manager.register("tinyurl",self)
  end
  def help m=nil, topic=nil
    "tinyurl [[url]...] => Create tinyurl's for list of urls."
  end
  def command m
    results = []
    m.params.each do |url|
      t = Tinyurl.new(url)
      results << "{ #{t.tiny} => #{t.original} }"
    end
    m.reply results.join(", ")
  end
end
