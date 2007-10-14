  class Meth::Plugin

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
      Meth::PluginManager._load(self.class)
    end

    # receives all messages
    def listen m
    end

    # receives privmsg's
    # which are address to this plugin
    def privmsg m
    end

  end


