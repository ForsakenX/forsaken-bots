module Meth

  require "#{ROOT}/lib/string.rb"
  class Plugins
    @@glob = "#{ROOT}/plugins/*.rb"
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
      list.detect{|p| p == plugin }
    end
    def self.do(plugin, method, args)
      unless detect(plugin)
        puts "Plugin does not exist"
        return false
      end
      load @@glob.gsub('*',plugin)
      plugin = plugin.camel_case
      unless plugin = Object.const_get(plugin)
        puts "Const does not exist"
        return false
      end
      i = plugin.new
      output = i.send(method,args)
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
      @channels = ["#kahn"]
      # allways last
      # calls post_init
      super *args
    end
  
    def privmsg m
      command(m) if m.command
    end
  
    def notice m
    end
  
    def command m
      case m.command
      when "help","",nil
        if (plugin = m.params.shift)
          m.command = plugin
          m.reply Plugins.do(m.command,'help',m)
        else
          m.reply "So far I only respond to: #{Plugins.list.join(', ')}"
        end
      else
        Plugins.do(m.command,'privmsg',m)
      end
    end
  
  end

end
