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
      begin
        _load plugin
        constant = Object.const_get(plugin.camel_case)
        @plugins[plugin.snake_case] = constant.new(@bot)
      rescue Exception
        puts "----------------------"
        puts "#{$!}\n#{$@.join("\n")}"
        puts "----------------------"
      end
      false
    end
  end

  # list of plugins
  def list
    Dir["#{DIST}/plugins/*.rb",@glob].map do |plugin|
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

  # plugin exists?
  def detect plugin
    list.detect{|p| p.downcase == plugin.downcase }
  end

  # loads a plugin
  def _load plugin
    load path(plugin)
    @bot.logger.info "Bot (#{bot.name}) Loaded Plugin (#{plugin.snake_case})"
  end

end
