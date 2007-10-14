# user model
class Irc::User

  #
  #  User Instance
  #
  
  # attributes of a user
  attr_accessor :server, :channel, :user, :host, :username,
                :nick, :flags, :realname
  
  def setup user
    # assign attributes
    @server   = user[:server]   # irc server user is on
    @channel  = user[:channel]  #
    @user     = user[:user]     # user name/uid on pc
    @host     = user[:host]     # user hostname
    @nick     = user[:nick]     # user irc nick
    @flags    = user[:flags]    # user flags
    @realname = user[:realname] # freeform realname
  end

  def username
    "#{@user}@#{@host}"
  end

  def initialize user
    setup user
  end

  def update user
    user.each do |prop,val|
      instance_variable_set(prop.to_s.gsub(/^/,'@').to_sym, val)
    end
  end

  def destroy
    @@users.delete self
  end

  #
  # User Instance Methods
  #

  # get user ip number
  require 'resolv'
  def ip
    return @ip if @ip
    begin
      return (@ip = Resolv.getaddress host)
    rescue Resolv::Error
      puts "DEBUG Resolv::Error #{$!}"
    end
    nil
  end

  #
  #  User Model (AR paradigm)
  #

  @@users = []

  def self.create user
    unless u = find_by_nick(user[:nick])
      u = new(user)
      @@users << u
    end
    u
  end

  def self.find nick
    return find_all if nick == :all
    return find_by_nick(nick)
  end

  def self.find_all
    @@users
  end

  def self.find_by_nick nick
    @@users.each do |user|
      return user if user.nick.downcase == nick.downcase
    end
    nil
  end

  #
  # Class Helpers
  # 

  def self.filter patterns=[]
    found = []
    @@users.map do |user|
      if patterns.length > 0
        matched = false
        patterns.each do |pattern|
          matched = true if user.nick =~ /#{pattern}/i
        end
        next if matched == false
      end
      next if ["ChanServ"].detect{|nick| user.nick == nick }
      found << user
    end
    found
  end

end

