require 'socket'
class Irc::Client < EM::Connection

  include EM::Protocols::LineText2
  include Irc::HandleMessage
  include Irc::Helpers

  @@logger = Logger.new(STDOUT)
  def self.logger; @@logger; end
  def self.logger=(logger); @@logger=logger; end
  def logger; @@logger; end
  def logger=(logger); @@logger=logger; end

  attr_reader :event, :name, :nick_sent, :realname, :server, :port, :username, :hostname, :config
  attr_accessor :nick, :ignored

  def initialize
    @name     = "RubyIrcClient"
    @nick     = "RubyIrcClient"
    @password = ""
    @realname = "RubyIrcClient"
    @server   = "irc.freenode.net"
    @port     = 6667
    @default_channels = ['#forsaken']
    @ignored  = []
    @event    = Event.new
    @timer    = Irc::Timer.new
    @username = Process.uid
    @servername = Socket.gethostname
  end

  def post_init
    @event.call('irc.post_init',nil)
    @@logger.info "Connected #{@name} to #{@server}:#{@port}"
    # send password
    send_data "PASS #{@password}\n" if @password
    # login
    send_data "USER #{@username} #{@servername} #{@server} :#{@realname}\n"
    # send initial nick
    send_nick @nick
  end

  def unbind
    @event.call('irc.unbind',nil)
    reconnect @server, @port
    post_init
  end

  def receive_line line
    time = Time.now
    @event.call('irc.receive_line',line)
    @@logger.info "<<< #{line}"
    handle_message line, time
    @@logger.info "Time Taken (seconds) => #{Time.now-time}"
  end

  def send_data line
#@timer.add_ounce( get_next_send_delay ){
    @@logger.info ">>> #{line}"
    @event.call('irc.send_data',line)
    super line
#}
  end

=begin
  def get_next_send_delay
    # settings
    @last_time_step = 0.15
    @last_time_max = 0.9
    @last_time_reset = -2
    # initial value
    # step .15 and max .9 good from silence
    @last_time = Time.now.to_f if @last_time.nil?
    @last_time_delay = 0.0 if @last_time_delay.nil?
    # increment delay step
    # and add delay to the timer
    # cap off at about max delay
    if (@last_time - Time.now.to_f) < @last_time_max
      @last_time_delay += @last_time_step
      @last_time += @last_time_delay
    end
    # difference to wait from now
    delay = @last_time - Time.now.to_f
    # make sure delay is in future
    if delay <= 0
      # if it's over a second old reset timers
      if delay <= @last_time_reset
        @last_time_delay = @last_time_step 
        @last_time = Time.now.to_f + @last_time_delay
        delay = @last_time - Time.now.to_f
      # other wise start decrementing the step
      else
        @last_time_delay -= @last_time_step*2 # since 1 step was added above
        @last_time = Time.now.to_f + @last_time_delay
        delay = @last_time - Time.now.to_f
      end
    end
    # return the delay
    logger.info "delay: #{delay}, step: #{@last_time_delay.to_s}"
    delay
  end
=end

end

