require 'resolv'
class Irc::User
  #
  #  User Model
  #
  @@users = []
  class << self
    def users; @@users; end
    def create user
      return u if u = find(user[:nick])
      u = new(user)
      @@users << u
      u
    end
    def find(nick)
      @@users.each do |user|
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
  attr_reader :realname, :user, :host, :channels
  attr_accessor :nick, :flags

  def initialize user
    @ip = nil
    @channels = {}
    @blocked = false
    @host =  nil
    @user =  nil
    @realname = nil
    @nick = nil
    @flags = nil
    update user
  end
  
  def update user
    user.each do |key,val|
      next if key == :channels || key == :host
      i = key.to_s.gsub(/^/,'@').to_sym
      instance_variable_set(i,val)
    end
    #
    @host = user[:host] unless ip_blocked?
    #
    if user[:channels]
      user[:channels].each do |channel|
        join channel
      end
    end
  end

  def join channel
    return if @channels[channel.downcase]
    @channels[channel.downcase] = Irc::Channel.join(channel)
  end
  
  def leave channel
    @channels.delete(channel.downcase)
    destroy if @channels.length < 1
  end
   
  def destroy
    @@users.delete self
  end

  #
  # Instance Helpers
  #

  def username
    "#{@user}@#{@host}"
  end

  def ip
    start = Time.now
    return nil if host == nil || ip_blocked?
    return @ip if @ip
    begin
      return (@ip = Resolv.getaddress host)
    rescue Exception #Resolv::Error
      Irc::Client.logger.error "Resolving: "+
                               self.inspect+
                               "seconds => #{Time.now-start}, "+
                               "error => #{$!}"
    end
    nil
  end

  def ip_blocked?
    return @blocked unless @blocked.nil?
    unafilliated = "unaffiliated\/#{Regexp.escape(@user.downcase)}"
    if user[:host] =~ /^#{unafilliated}$/
      @blocked = true
    else
      @blocked = false
    end
    @blocked
  end

  def to_s
    @nick
  end

end

