class Irc::Plugin

  # defaults
  def pre_init; end
  def post_init; end

  # pass down instance of bot
  def initialize(bot)
    @bot = bot
    # list of commands
    @commands = []
    # list of help messages
    @help = {}
    # helper for users
    self.send(:pre_init)
    # load commands
    @commands.each do |command|
      callback = Proc.new{|m| self.send(command.to_sym,m) }
      @bot.command_manager.register(command.to_s,self,callback)
    end
    # register message call backs
    @message_callbacks = {}
    %w{topic quit part listen privmsg notice join}.each do |type|
      if respond_to?(type.to_sym)
        message  = "irc.message.#{type}"
        callback = Proc.new{|message| send(type.to_sym, message) }
        @message_callbacks[message] = callback
        @bot.event.register(message,callback)
      end
    end
    # helper for users
    self.send(:post_init)
  end

  # reload the plugin
  def reload
    @bot.plugin_manager._load(self.class.name.snake_case)
  end

  # cleanup the plugin
  def cleanup
    @message_callbacks.each { |message,callback|
      @bot.event.unregister(message,callback)
    }
    @bot.command_manager.cleanup(self)
  end

  # automated help method
  def help m=nil, topic=nil
    return @help if @help.is_a?(String)
    # extract values
    params = m.params.dup
    command = params.shift
    # show help for command
    if @help.has_key?(m.command.to_sym)
      # try to get help for a topic
      if (command = @help[m.command.to_sym]).is_a?(Hash)
        # topic given
        if (!topic.nil?) && command.has_key?(topic)
          # topic specific help
          command[topic]
        # no topic given
        else
          # help for the command should be set to nil
          command[nil]
        end
      # return help for command
      else
        command
      end
    # default help message
    else
      # default help message
      if @help.has_key?(:default)
        @help[:default]
      # join all helps to create default
      else
        @help.keys.map{|k|@help[k]}.join(',  ')
      end
    end
  end

  def plugins
    @bot.plugins
  end

end
