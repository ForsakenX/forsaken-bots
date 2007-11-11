class Meth::Plugin

  # pass down instance of bot
  def initialize(bot)
    @bot = bot
    # register message call backs
    %w{unknown quit part listen privmsg notice join}.each do |type|
      @bot.event.register("irc.message.#{type}",Proc.new{|message|
        send(type.to_sym, message) if respond_to?(type.to_sym)
      })
    end
  end

  # reload the plugin
  def reload
    @bot.plugin_manager._load(self.class.name.snake_case)
  end

  def cleanup
    @bot.command_manager.cleanup(self)
  end

end
