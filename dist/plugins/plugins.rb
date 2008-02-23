class Plugins < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register('plugins',self)
  end
  def help m=nil, topic=nil
    "plugins => Display list of plugins.  "+
    "plugins enabled [plugin] => Display enabled plugins.  "+
    "Accepts [plugin] to check if a plugin is enabled.  "+
    "plugins loaded => Lists loaded plugins. "
  end
  def command m
    case m.params.shift
    when "enabled"
      if plugin = m.params.shift
        m.reply @bot.plugin_manager.enabled?(plugin)
      else
        m.reply @bot.plugin_manager.enabled.sort.join(', ')
      end
    when "loaded"
      m.reply @bot.plugin_manager.loaded.sort.join(', ')
    when "",nil
      m.reply @bot.plugin_manager.list.sort.join(', ')
    end
  end
end
