class Meth::Plugin

  # should reload automatically ?
  @@reload = false

  # accessor
  def self.reload; @@reload; end

  # pass down instance of bot
  def initialize(bot)
    @bot = bot
    # register command callbak
    @bot.event.register("command.#{self.class.name.downcase}",Proc.new{|m|
      next unless respond_to? :command
      command(m)
    })
    # register message call backs
    %w{unknown quit part listen privmsg notice join}.each do |type|
      @bot.event.register("irc.message.#{type}",Proc.new{|message|
        send(type.to_sym, message) if respond_to?(type.to_sym)
      })
    end
  end

  # reload the plugin
  def reload
    Meth::PluginManager._load(self.class)
  end


end

