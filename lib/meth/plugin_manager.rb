class Meth::PluginManager

  # path to plugins
  @@glob    = "#{DIST}/plugins/*.rb"
  
  # plugin instances
  @@plugins = {}

  class << self

    # accessor to plugin instances
    def plugins; @@plugins; end

    # list of plugins
    def list
      Dir[@@glob].map do |plugin|
        File.basename(plugin).gsub('.rb','')
      end
    end
    
    # path to plugin
    def path plugin
      @@glob.gsub('*',plugin.snake_case)
    end

    # plugin executable?
    def executable? plugin
      FileTest.executable?(path(plugin))
    end

    # list of enabled plugins
    def enabled
      list.collect{|plugin| plugin if enabled?(plugin) }
    end

    # plugin enabled?
    def enabled? plugin
      return true if @@plugins[plugin]
      return true if executable?(plugin)
      false
    end

    # plugin exists?
    def detect plugin
      list.detect{|p| p.downcase == plugin.downcase }
    end

    # load all the plugins
    def startup bot
      enabled.each do |plugin|
        begin
          load path(plugin)
          constant = Object.const_get(plugin.camel_case)
          @@plugins[plugin.snake_case] = constant.new(bot)
          $logger.info "Loaded Plugin '#{plugin.snake_case}'"
        rescue Exception
          puts "----------------------"
          puts "#{$!}\n#{$@.join("\n")}"
          puts "----------------------"
        end
        false
      end
    end

  end
end
