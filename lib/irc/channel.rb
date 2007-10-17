class Irc::Channel
  private_instance_methods :new
  #
  # Class
  #
  @@channels = {}  # list of channels
  class << self
    def channels;   @@channels; end
    def join(server,channel)
      unless @@channels[channel].nil?
        return @@channels[channel]
      end
      c = new(server,channel)
      @@channels[channel] = c
    end
    def part(server,channel)
      @@channels[channel] = nil
    end
  end
  #
  # Instance
  #
  attr_reader :server
  attr_writer :topic
  def initialize(server,channel)
    @server = server
    @name   = channel
    @topic  = nil
  end
  def users
    users = []
    Irc::User.users.each do |user|
      user.channels.each do |name,channel|
        users << user if @name == name &&
                         @server[:host] == channel.server[:host] &&
                         @server[:port] == channel.server[:port]
      end
    end
    users
  end
end
