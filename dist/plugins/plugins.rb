class Plugins < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register('plugins',self)
  end
  def help m=nil, topic=nil
    "plugins => Display list of plugins.  "+
    "plugins enabled [plugin] => Display enabled plugins.  "+
    "Accepts [plugin] to check if a plugin is enabled.  "+
    "plugins loaded => Lists loaded plugins. "+
    "plugins reload [plugin] => Reloads the given [plugin]"
  end
  def command m
    @params = m.params.dup
    case @params.shift
    when "enabled"
      if plugin = @params.shift
        m.reply @bot.plugin_manager.enabled?(plugin)
      else
        m.reply @bot.plugin_manager.enabled.sort.join(', ')
      end
    when "loaded"
      m.reply @bot.plugin_manager.loaded.sort.join(', ')
    when "reload"
      reload m
    when "",nil
      m.reply @bot.plugin_manager.list.sort.join(', ')
    end
  end
  def reload m

    command = @params.shift

    if command.nil?
      plugins = @bot.plugin_manager.reload_all
      m.reply "Reloaded Plugins: #{plugins.join(', ')}"
      return
    end

      # use command name to find plugin
      if c = @bot.command_manager.commands[command]
        plugin = c[:obj].class.name.snake_case
      # default use plugin name
      else
        plugin = command
      end
      #
      unless @bot.plugin_manager.exists?(plugin)
        m.reply "Plugin '#{plugin}' does not exist."
        return
      end
      unless @bot.plugin_manager.enabled?(plugin)
        m.reply "Plugin '#{plugin}' is not enabled."
        return
      end
      unless @bot.plugin_manager.plugins[plugin]
        if (error = @bot.plugin_manager._load(plugin)) === true
          m.reply "Plugin '#{plugin}' loaded"
        else
          m.reply "Plugin '#{plugin}' failed to load.  " +
                  error
        end
        return
      end
      if (error = @bot.plugin_manager.plugins[plugin].reload) === true
        m.reply "Plugin '#{plugin}' reloaded"
      else
        m.reply "Plugin '#{plugin}' failed to reload:  "+
                error
      end
  end
end
