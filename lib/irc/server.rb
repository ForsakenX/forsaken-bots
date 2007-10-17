class Irc::Server
  private_class_method :new
  #
  # Class
  #
  @@servers = {}
  class << self
    def servers; @@servers; end
    def find_by_name n
      @@servers.each do |name,server|
        return server if n == name
      end
    end
    def create(name,host,port)
      if find_by_name name
        throw "Server by that name allready exists"
      end
      @@servers[name] = new(name,host,port)
    end
    def destroy(name)
      @@servers[name] = nil
    end
  end
  #
  # Instance
  #
  attr_reader :name, :host
  def initialize(name,host,port)
    @name     = name
    @host     = host
    @port     = port
    @channel  = Irc::Channel.clone
    @channels = @channel.channels
    @channel.server = self
  end
  def users
    users = []
    @channels.each do |name,channel|
      users.concat channel.users
    end
    users
  end
end
