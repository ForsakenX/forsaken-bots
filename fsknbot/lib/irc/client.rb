require 'socket'
class Irc::Client < EM::Connection

  include EM::Protocols::LineText2
  include Irc::Helpers

  def plugins; @plugin_manager.plugins; end
  def commands; @command_manager.commands; end

  attr_reader :event, :plugin_manager, :command_manager
  attr_accessor :nick

  def initialize
    @nick     = CONFIG['nick']
    @event    = Event.new
    @timer    = Timer.new
    @command_manager = Irc::CommandManager.new(self)
    @plugin_manager  = Irc::PluginManager.new(self)
  end

  def post_init
    @event.call('irc.post_init',nil)
    send_join ['#forsaken']
    LOGGER.info "Connected"
  end

  def unbind
    puts "unbind"
    @event.call('irc.unbind',nil)
    reconnect CONFIG['server'], CONFIG['port']
    post_init
  end

  def receive_line line
begin
    time = Time.now
    @event.call('irc.message.listen',[self,line,time])
    LOGGER.info "<<< #{line}"
    LOGGER.info "Time Taken (seconds) => #{Time.now-time}"
rescue Exception
  puts $!
end
  end

  def send_data line
    LOGGER.info ">>> #{line}"
    @event.call('irc.send_data',line)
    super line
  end

end

