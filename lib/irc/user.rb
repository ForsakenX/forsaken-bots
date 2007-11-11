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
            matched = true if user.nick =~ /#{Regexp.escape(pattern)}/i
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
      next if key == :channels || key == :host
      i = key.to_s.gsub(/^/,'@').to_sym
      instance_variable_set(i,val)
    end
    #
    @host = nil
    @host = user[:host] if ! (user[:host] =~ /^unaffiliated\/#{@nick.downcase}$/)
    #
    if user[:channels]
      user[:channels].each do |channel|
        join channel
      end
    end
  end
  # join a channel
  def join channel
    return if @channels[channel.downcase]
    @channels[channel.downcase] = Irc::Channel.join(@server,channel)
  end
  #
  def leave channel
    @channels.delete(channel.downcase)
    puts "[-------------------] #{@channels.inspect}"
    if @channels.length < 1
      puts "[-------------------] @channels.length < 1"
      destroy
    end
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
  def ip
    return nil if host == nil
    return @ip if @ip
    begin
      return (@ip = Resolv.getaddress host)
    rescue Exception #Resolv::Error
      puts "DEBUG Resolv::Error #{$!}"
    end
    nil
  end
end

