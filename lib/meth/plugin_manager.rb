class Meth::PluginManager

  attr_reader :bot, :glob, :plugins

  def initialize(bot)
    # we belong to this bot instance
    @bot = bot
    # path to plugins
    @glob = "#{DIST}/bots/#{$bot}/plugins/*.rb"
    # plugin instances
    @plugins = {}
    # load plugins
    startup
  end

  # load all the plugins
  def startup
    enabled.each do |plugin|
      _load plugin
    end
    @bot.event.call('meth.plugins.loaded',nil)
  end

  # list of plugins
  def list
    Dir[@glob,"#{DIST}/plugins/*.rb"].map do |plugin|
      File.basename(plugin).gsub('.rb','')
    end
  end
    
  # path to plugin
  def path plugin
    bot_path = @glob.gsub('*',plugin.snake_case)
    global_path = "#{DIST}/plugins/#{plugin.snake_case}.rb"
    return bot_path if FileTest.exists?(bot_path) # bot_path takes precedence
    return global_path if FileTest.exists?(global_path) # global plugin?
    bot_path # default bot_path
  end

  #
  def exists? plugin
    FileTest.exists?(path(plugin))
  end

  # plugin executable?
  def executable? plugin
    FileTest.executable?(path(plugin))
  end

  # list of enabled plugins
  def enabled
    list.select{|plugin| plugin if enabled?(plugin) }
  end

  # plugin enabled?
  def enabled? plugin
    return true if @plugins[plugin]
    return true if executable?(plugin)
    false
  end

  # list loaded plugins
  def loaded
    @plugins.map{|name,instance| name }
  end

  # plugin exists?
  def detect plugin
    list.detect{|p| p.downcase == plugin.downcase }
  end

  def unload plugin
    if p = @plugins[plugin]
      begin
        p.cleanup
      rescue Exception
        @bot.logger.warn "[unload plugin error] #{$!}\n#{$@.join("\n")}"
      end
      @plugins.delete(p)
    end
  end

  def reload plugin
    unload plugin
    load path(plugin)
  end

  # loads a plugin
  # expects snake case
  def _load plugin
    reload plugin
    begin
      constant = Object.const_get(plugin.camel_case)
      @plugins[plugin] = constant.new(@bot)
    rescue Exception
      @bot.logger.warn "[_load plugin error] #{$!}\n#{$@.join("\n")}"
    end
    @bot.logger.info "Bot (#{bot.name}) Loaded Plugin (#{plugin.snake_case})"
    @bot.event.call('meth.plugin.loaded', plugin)
  end

  def reload_all
    enabled.each do |plugin|
      @plugins[plugin].reload
    end
  end

end
