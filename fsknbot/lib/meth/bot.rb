class Meth::Bot < Irc::Client

  attr_reader   :plugin_manager, :command_manager
  attr_accessor :target
  def plugins; @plugin_manager.plugins; end
  def commands; @command_manager.commands; end

  def initialize
    # client stuff
    super
    @name     = CONFIG['name']
    @nick     = CONFIG['nick']
    @password = CONFIG['password']
    @realname = CONFIG['realname']
    @server   = CONFIG['server']
    @port     = CONFIG['port']
    @default_channels = CONFIG['channels']
    # bot stuff
    @target = CONFIG['target']||nil
    @command_manager = Meth::CommandManager.new(self)
    @plugin_manager  = Meth::PluginManager.new(self)
  end

end

