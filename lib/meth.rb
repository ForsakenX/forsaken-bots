module Meth

  require "#{ROOT}/lib/string.rb"
  class Plugins
    @@glob = "#{DIST}/plugins/*.rb"
    def initialize
    end
    def self.plugins
      Dir[@@glob]
    end
    def self.list
      plugins.map do |plugin|
        File.basename(plugin).gsub('.rb','')
      end
    end
    def self.detect plugin
      list.detect{|p| p.downcase == plugin.downcase }
    end
    def self.do(plugin, method, m)
      unless detect(plugin)
        m.reply "Plugin '#{plugin}' does not exist"
        return false
      end
      load @@glob.gsub('*',plugin)
      plugin = plugin.camel_case
      unless plugin = Object.const_get(plugin)
        m.reply "Const '#{plugin}' does not exist"
        return false
      end
      i = plugin.new
      if i.respond_to?(method.to_sym)
        output = i.send(method,m)
      else
        m.reply "Method '#{method}' is not a member of plugin '#{plugin}'"
        return false
      end
      i = nil
      output
    end
  end

  require "#{ROOT}/lib/irc"
  class Bot < Irc::Client

    @@server  = "irc.blitzed.org"
  
    def initialize *args
      # settings
      @nick     = "MethBot"
      @realname = "Meth Killer Bot 0.000001"
      @channels = ["#tester","#kahn"]
      # allways last
      # calls post_init
      super *args
    end
  
    def privmsg m
      command(m) if m.command
    end
  
    def command m
      Plugins.do(m.command,'privmsg',m)
    end
  
  end

end
