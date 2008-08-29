class Irc::Channel

  #
  # Class
  #

  private_instance_methods :new
  @@channels = {}
  class << self
    def channels; @@channels; end
    def join(channel)
      _channel = channel.downcase
      return @@channels[_channel] unless @@channels[_channel].nil?
      c = new(channel)
      @@channels[_channel] = c
    end
    def part(channel)
      @@channels.delete(channel.downcase)
    end
  end
  
  #
  # Instance
  #

  attr_reader   :name
  attr_accessor :mode, :topic
  def initialize(channel,mode=nil)
    @name   = channel
    @topic  = nil
    @mode   = mode
  end
  def users
    users = []
    Irc::User.users.each do |user|
      user.channels.each do |name,channel|
        users << user if @name.downcase == name.downcase
      end
    end
    users
  end
  def to_s
    @name
  end
end
