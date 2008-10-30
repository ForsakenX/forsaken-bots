require 'socket'
class Irc::Client < EM::Connection

  include EM::Protocols::LineText2

  def plugins; @plugin_manager.plugins; end
  def commands; @command_manager.commands; end

  attr_reader :event, :plugin_manager, :command_manager
  attr_accessor :nick

  def initialize
    @nick     = 'FsknBot'
    @event    = Event.new
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
    reconnect 'localhost', 6667
    post_init
  end

  def receive_line line
    time = Time.now
    begin
      @event.call('irc.message.listen',line)
    rescue Exception
      puts $!
    end
    LOGGER.info "<<< #{line}"
    LOGGER.info "Time Taken (seconds) => #{Time.now-time}"
  end

  def send_data line
    LOGGER.info ">>> #{line}"
    @event.call('irc.send_data',line)
    super line
  end

  #
  # Helpers
  #

  def channels
    Irc::Channel.channels
  end

  def say to, message
    sender :privmsg, to, message
  end
  alias_method :msg, :say

  def notice to, message
    sender :notice, to, message
  end

  def sender type, to, message
    types = {
      :privmsg => "PRIVMSG",
      :notice  => "NOTICE",
    }
    message = message.to_s if message.respond_to?(:to_s)
    return message unless message
    # for each line
    message.split("\n").each do |message|
      # can't add up to more than 512 bytes on reciever side
      # this stops worsd from getting cut up
      message.scan(/.{1,280}[^ ]{0,100}/m){|chunk|
        next if chunk.length < 1
        send_data "#{types[type]} #{to} :#{chunk}\n"
      }
    end
    message
  end

  def send_join channels
    return if channels.nil?
    channels = channels.split(' ') if channels.is_a? String
    channels.each do |channel|
     send_data "JOIN #{channel.to_s}\n"
    end
  end

end

