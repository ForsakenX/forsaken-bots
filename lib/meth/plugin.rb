class Meth::Plugin

  # should reload automatically ?
  @@reload = false

  # accessor
  def self.reload; @@reload; end

  # pass down instance of bot
  def initialize(bot)
    @bot = bot
    # register command callbak
    @bot.event.register("command.#{self.class.name.downcase}",Proc.new{|m|command(m)})
    # register message call backs
    %w{unknown quit part listen privmsg notice join}.each do |type|
      @bot.event.register("message.#{type}",Proc.new{|message|
        next unless method_defined? m.to_sym
        self.send(m.to_sym, message)
      })
    end
  end

  # reload the plugin
  def reload
    Meth::PluginManager._load(self.class)
  end

end

