module Meth

  class Plugin

    # should reload automatically ?
    @@reload = false

    def self.reload; @@reload; end

    def initialize(client)
      @client = client
    end

    # reload the plugin
    def reload
      PluginManager._load(self.class)
    end

  end

  require "#{ROOT}/lib/string.rb"
  class PluginManager
    @@glob    = "#{DIST}/plugins/*.rb"
    @@plugins = {}
    def self.plugins; @@plugins; end
    def self.list
      Dir[@@glob].map do |plugin|
        File.basename(plugin).gsub('.rb','')
      end
    end
    def self.path plugin
      @@glob.gsub('*',plugin.snake_case)
    end
    def self.executable? plugin
      FileTest.executable?(path(plugin))
    end
    def self.enabled
      list.collect{|plugin| plugin if enabled?(plugin) }
    end
    def self.enabled? plugin
      return true if @@plugins[plugin]
      return true if executable?(plugin)
      false
    end
    def self.detect plugin
      list.detect{|p| p.downcase == plugin.downcase }
    end
    def self._load(plugin,m)
      unless detect(plugin)
        puts m.reply "ERROR - Plugin '#{plugin}' does not exist."
      end
      unless enabled?(plugin)
        puts m.reply "Plugin '#{plugin}' is not enabled."
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
    def self.find_const(plugin,m)
      # get constant
      get = Proc.new{
        begin
          const_get(plugin.camel_case)
        # constant does not exist
        rescue NameError
          nil
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
      puts m.reply "ERROR - Loaded plugin '#{plugin.snake_case}' "+
                   "but did not find constant '#{plugin.camel_case}'"
      nil
    end
    def self.find_inst(plugin,m)
      # get the constant from plugin name
      return nil unless const = find_const(plugin,m)
      # find the instance
      unless inst = @@plugins[plugin.snake_case]
        # if we dont have an instance yet
        # create one and pass in instance of client
        begin
          @@plugins[plugin.snake_case] = const.new(m.client)
          puts "NOTICE - Initialized Plugin '#{const.class}'"
        rescue Exception
          puts "----------------------"
          puts m.reply "ERROR - Plugin '#{const.class}' failed to initialize"
          puts $!
          puts $@.join("\n")
          puts "----------------------"
          return nil
        end
      end
      # return it
      @@plugins[plugin.snake_case]
    end
    def self.do(plugin, method, m)
      # out instance of plugin
      i=nil
      # find or create instance of plugin
      return unless i = find_inst(plugin,m)
      # check if the plugin has the desired method
      unless i.respond_to?(method.to_sym)
        message = "ERROR - Method '#{method}' is not a member of plugin '#{plugin}'"
        puts m.reply message
        return
      end
      # run the method
      i.send(method,m) unless i.nil?
    end
  end

  require "#{ROOT}/lib/irc"
  class Bot < Irc::Client

    attr_accessor :bot

    @@server  = "irc.blitzed.org"
    
    def initialize *args
      # settings
      @nick     = "MethBot"
      @realname = "Meth Killer Bot 0.000001"
      @channels = ["#tester"]#,"#kahn"]
      # provided to plugins
      @bot = self
      # allways last
      # calls post_init
      super *args
    end

    def plugins
      PluginManager.plugins
    end
 
    def privmsg m
      command(m) if m.command
    end
  
    def command m
      PluginManager.do(m.command,'privmsg',m)
    end
  
  end

end
