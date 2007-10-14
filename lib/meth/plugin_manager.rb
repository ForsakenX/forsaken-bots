class Meth::PluginManager
  @@glob    = "#{DIST}/plugins/*.rb"
  @@plugins = {}
  class << self
    def plugins; @@plugins; end
    def list
      Dir[@@glob].map do |plugin|
        File.basename(plugin).gsub('.rb','')
      end
    end
    def path plugin
      @@glob.gsub('*',plugin.snake_case)
    end
    def executable? plugin
      FileTest.executable?(path(plugin))
    end
    def enabled
      list.collect{|plugin| plugin if enabled?(plugin) }
    end
    def enabled? plugin
      return true if @@plugins[plugin]
      return true if executable?(plugin)
      false
    end
    def detect plugin
      list.detect{|p| p.downcase == plugin.downcase }
    end
    def _load(plugin,m)
      unless detect(plugin)
        print "ERROR - "
        puts m.reply("Plugin '#{plugin}' does not exist.")
        return false
      end
      unless enabled?(plugin)
        print "ERROR - "
        puts m.reply("Plugin '#{plugin}' is not enabled.")
        return false
      end
      begin
        load path(plugin)
        puts "NOTICE - Loaded Plugin '#{plugin.snake_case}'"
        return true
      rescue SyntaxError
        puts "----------------------"
        puts "ERROR - #{$!}"
        puts $@.join("\n")
        puts "----------------------"
        return false
      end
      false
    end
    def find_const(plugin,m)
      # get constant
      get = Proc.new{
        if Object.const_defined?(plugin.camel_case)
          next Object.const_get(plugin.camel_case)
        else
          next nil
        end
      }
      # our constant
      constant = nil
      # try get constant
      if constant = get.call()
        # see if plugin should be reloaded
        return constant unless constant.reload
        puts "NOTICE - Reloading Plugin '#{plugin.snake_case}'"
      end
      # did not get constant or wants a reload
      # try to load plugin
      return nil unless _load(plugin,m)
      # try get constant
      return constant if constant = get.call()
      # failed
      print "ERROR - "
      puts m.reply("Loaded plugin '#{plugin.snake_case}' "+
                   "but did not find constant '#{plugin.camel_case}'")
      nil
    end
    def find_inst(plugin,m)
      # get the constant from plugin name
      return nil unless const = find_const(plugin,m)
      # find the instance
      unless inst = @@plugins[plugin.snake_case]
        # if we dont have an instance yet
        # create one and pass in instance of client
        begin
          @@plugins[plugin.snake_case] = const.new(m.client)
          puts "NOTICE - Initialized Plugin '#{const.name}'"
        rescue Exception
          puts "----------------------"
          print "ERROR - "
          puts m.reply("Plugin '#{const.class}' failed to initialize")
          puts $!
          puts $@.join("\n")
          puts "----------------------"
          return nil
        end
      end
      # return it
      @@plugins[plugin.snake_case]
    end
    def do_all(method,m)
      enabled.each do |plugin|
        self.do(plugin,method,m)
      end
    end
    def do(plugin, method, m)
      i=nil
      # find or create instance of plugin
      return unless i = find_inst(plugin,m)
      # check if the plugin has the desired method
      unless i.respond_to?(method.to_sym)
        message = "Method '#{method}' is not a member of plugin '#{plugin}'"
        print "ERROR - "
        puts m.reply(message)
        return
      end
      # run the method
      begin
        i.send(method,m) unless i.nil?
      rescue Exception
        puts "----------------------"
        puts "ERROR - Calling method '#{method}' of plugin '#{plugin}': #{$!}"
        puts m.reply($!)
        puts $@.join("\n")
        puts "----------------------"
        return false
      end
    end
    def startup bot
      enabled.each do |plugin|
        begin
          load path(plugin)
          constant = Object.const_get(plugin.camel_case)
          @@plugins[plugin.snake_case] = constant.new(bot)
          puts "Loaded Plugin '#{plugin.snake_case}'"
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
