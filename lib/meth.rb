module Meth

  class Plugin

    # should reload automatically ?
    @@reload = false

    # accessor
    def self.reload; @@reload; end

    # pass down instance of bot
    def initialize(bot)
      @bot = bot
    end

    # reload the plugin
    def reload
      PluginManager._load(self.class)
    end

    # receives all messages
    def listen m
    end

    # receives privmsg's
    # which are address to this plugin
    def privmsg m
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
    def self.do_all(method,m)
      enabled.each do |plugin|
        self.do(plugin,method,m)
      end
    end
    def self.do(plugin, method, m)
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

  class BotManager
    @@bots = {}
    class << self
      def bots; @@bots; end
      def connect(config)
        begin
          bot = Meth::Bot.new(config)
          @@bots[bot.name] = bot
          puts "Connecting #{bot.name} to #{bot.server}:#{bot.port}"
          EM::connect(bot.server, bot.port, bot)
        rescue
          puts "Error: #{$!}"
          $@.each do |line| puts "#{line}" end
        end
      end
    end
  end

  require "#{ROOT}/lib/irc"
  class Bot < Irc::Client

    #
    # Instance
    #

    attr_accessor :name, :nick, :server, :channels, :realname, :bot, :target

    def plugins; PluginManager.plugins; end
    def bots;    BotManager.bots;       end

    def initialize(config)
      # defaults
      super
      # copy in configs
      @name     = config['name']     || "freenode"
      @target   = config['target']   || ","
      @server   = config['server']   || "irc.freenode.org"
      @nick     = config['nick']     || "MethBot_#{username}_#{hostname}"
      @channels = config['channels'] || ["#methbot"]
      @realname = config['realname'] || "MethBot beta"
      # automatics
      @bot      = self
    end

    #
    # Callbacks
    #

    def _listen m
      PluginManager.do_all('listen',m)
    end

    def _privmsg m
      puts ">>> "+
           "#{@bot.name} #{m.channel} " +
           "(#{Time.now.strftime('%I:%M:%S %p')}) "+
           "#{m.source.nick}: #{m.message}"
      do_command(m)
    end

    def _notice m
      puts m.line
    end

    def _join m
      puts m.line
    end

    def _part m
      puts m.line
    end
  
    def _quit m
      puts m.line
    end

    def _unknown m
      puts "Unknown Message -> #{m.line}"
    end

    #
    #  Console
    #  Loggers
    #

    def post_init *args
      super *args
      puts "Connected #{@name} to #{@server}:#{@port}"
    end

    def say to, message
      puts "<<< "+
           "#{@bot.name} #{to} " +
           "(#{Time.now.strftime('%I:%M:%S %p')}) "+
           "#{@bot.nick}: #{message}"
      super(to,message)
    end
    
    def receive_line line
      $logger.info "<<< #{line}"
      super line
    end

    def send_data line
      $logger.info ">>> #{line}"
      super line
    end

    #
    # Bot Methods
    #

    def do_command m

      # m.message with a command is one of the following
      # ",hi 1 2 3"
      # "MethBot: hi 1 2 3"

      # must become...
      # m.command => hi
      # m.message => 1 2 3

      # look for our nick or target as first word
      # then extract them from the message

      # "(<nick>: |<target>)"
      unless is_command = !m.message.slice!(/^#{@nick}: /).nil?
        # addressed to target
        unless @target.nil?
          is_command = !m.message.slice!(/^#{@target}/).nil?
        end
      end

      # "hi 1 2 3"
      # now that nick/target is extracted
      # the rest is the message
      # that includes the command and params

      # if its a pm then its allways a command
      is_command = m.personal if !is_command

      # at this point if its not a command
      # where done working with this message
      return unless is_command

      # %w{hi 1 2 3}
      # split words in line
      m.params = line.split(' ')

      # "hi"
      # the command
      m.command = m.params.shift

      # invoke the plugin (command)
      PluginManager.do(command,'privmsg',m)

    end
  end
end
