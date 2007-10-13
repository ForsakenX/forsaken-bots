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
    def self.find_const(plugin,m)
      # get constant
      get = Proc.new{
        const_defined?(plugin.camel_case) ?
          const_get(plugin.camel_case) :
          nil
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
    def self.do(plugin, method, m)
      # out instance of plugin
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
  end

  require "#{ROOT}/lib/irc"
  class Bot < Irc::Client

    attr_accessor :name, :nick, :server, :channels, :realname, :bot

    def initialize(config)
      # defaults
      super
      # copy in configs
      @server   = config['server']   || "irc.freenode.org"
      @name     = config['name']     || "freenode"
      @nick     = config['nick']     || "MethBot_#{username}_#{hostname}"
      @channels = config['channels'] || ["#methbot"]
      @realname = config['realname'] || "MethBot beta"
      # automatics
      @bot      = self
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
   
    def receive_line line
      $logger.info "<<< #{line}"
      super line
    end

    def send_data line
      $logger.info ">>> #{line}"
      super line
    end

  end

end
