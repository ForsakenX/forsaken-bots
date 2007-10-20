require 'resolv'
class Irc::User
  private_instance_methods :new
  #
  #  User Model
  #
  @@users = []
  class << self
    def users; @@users; end
    def create user
      unless u = find(user[:server],user[:nick])
        u = new(user)
        @@users << u
      end
      u
    end
    def find(server,nick)
      @@users.each do |user|
        next unless user.server[:host] == server[:host]
        return user if user.nick.downcase == nick.downcase
      end
      nil
    end
    #
    # Class Helpers
    # 
    def filter(users,patterns=[])
      found = []
      users.each do |user|
        if patterns.length > 0
          matched = false
          patterns.each do |pattern|
            matched = true if user.nick =~ /#{pattern}/i
          end
          next if matched == false
        end
        next if ["ChanServ"].detect{|nick| user.nick.downcase == nick.downcase }
        found << user
      end
      found
    end
  end
  #
  #  User Instance
  #
  # reader/writers
  attr_reader :server, :realname, :user, :host, :channels
  attr_accessor :nick, :flags
  # 
  def initialize user
    @ip = nil
    @channels = {}
    update user
  end
  #
  def update user
    user.each do |key,val|
      next if key == :channels 
      i = key.to_s.gsub(/^/,'@').to_sym
      instance_variable_set(i,val)
    end
    return if user[:channels].nil?
    user[:channels].each do |channel|
      join channel
    end
  end
  # join a channel
  def join channel
    return if @channels[channel]
    @channels[channel] = Irc::Channel.join(@server,channel)
  end
  #
  def leave channel
    @channels.each do |name,c|
      @channels.delete(channel) if name == channel
    end
    #destroy unless @channels.length
  end
  # 
  def destroy
    @@users.delete self
  end
  #
  # Instance Helpers
  #
  def username; "#{@user}@#{@host}"; end
  # get user ip number
  require 'resolv'
  def ip
    return @ip if @ip
    begin
      return (@ip = Resolv.getaddress host)
    rescue Exception #Resolv::Error
      puts "DEBUG Resolv::Error #{$!}"
    end
    nil
  end
end

