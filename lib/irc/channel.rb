class Irc::Channel
  private_instance_methods :new
  #
  # Class
  #
  @@channels = {}  # list of channels
  class << self
    def channels;   @@channels; end
    def join(server,channel)
      _channel = channel.downcase
      unless @@channels[_channel].nil?
        return @@channels[_channel]
      end
      c = new(server,channel)
      @@channels[_channel] = c
    end
    def part(server,channel)
      @@channels[channel.downcase] = nil
    end
  end
  #
  # Instance
  #
  attr_reader :server, :name
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
