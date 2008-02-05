class Meth::Plugin

  # pass down instance of bot
  def initialize(bot)
    @bot = bot
    # register message call backs
    @message_callbacks = {}
    %w{unknown quit part listen privmsg notice join}.each do |type|
      if respond_to?(type.to_sym)
        message  = "irc.message.#{type}"
        callback = Proc.new{|message| send(type.to_sym, message) }
        @message_callbacks[message] = callback
        @bot.event.register(message,callback)
      end
    end
  end

  # reload the plugin
  def reload
    @bot.plugin_manager._load(self.class.name.snake_case)
  end

  def cleanup
    @message_callbacks.each { |message,callback| @bot.event.unregister(message,callback) }
    @bot.command_manager.cleanup(self)
  end

end
