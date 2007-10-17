class Reload < Meth::Plugin
  def help m=nil
    "reload [plugin] => Reloads the given [plugin]"
  end
  def command m
    plugin = m.params.shift
    case plugin
    when "",nil
      m.reply help
    else
      unless Meth::PluginManager.enabled?(plugin)
        m.reply "Plugin is not loaded"
        return
      end
      if Meth::PluginManager._load(plugin)
        m.reply "Plugin '#{plugin}' reloaded"
      else
        m.reply "Plugin '#{plugin}' failed to reload."
      end
    end
  end
end
