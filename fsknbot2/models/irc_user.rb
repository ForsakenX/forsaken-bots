require 'resolv'
class IrcUser

  #
  # public api
  #

  ## holds a list of hidden users
  @@hidden = %w{chanserv}

  ## holds list of users
  @@users = []

  class << self
  
    ## readers
    def users; @@users; end
  
    ## find a user
    def find_by_nick nick
      @@users.each {|u| return u if u.nick == nick }
      nil
    end
  
    ## delete a user
    def delete_by_nick nick
      if user = IrcUser.find_by_nick(nick)
        @@users.delete user
      end
      user
    end

=begin
    ## get unique-ip list
    def users_by_ip
      unique = []
      @@users.each do |user|
        next if user.ip.nil?
        unique.each do |uniq|
        end
      end
    end
=end
  
    ## get user ip
    def get_ip user
      ignored = ["unaffiliated/#{user.nick}","services."]
      return nil if ignored.include? user.host
      return Resolv.getaddress(user.host)
    rescue Exception #Resolv::Error
      puts "--- ResolvError => #{$!}"
      nil
    end

  end

  #
  # instance api
  #

  ## reads
  attr_accessor :nick, :host, :ip

  ## instance constructor
  def initialize hash

    # populate values
    @nick = hash[:nick]
    @host = hash[:host]
    @ip   = IrcUser.get_ip(self)

    # add to list
    @@users << self unless @@hidden.include?(hash[:nick])

  end

end
