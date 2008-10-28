require 'resolv'

#
# Public API
#

class IrcUser
  class << self

    @@hidden = %w{chanserv epsy}

    @@users = []; def users; @@users; end
  
    def find_by_nick nick
      @@users.detect{|u| u.nick == nick }
    end
  
    def delete_by_nick nick
      if user = IrcUser.find_by_nick(nick)
        @@users.delete user
      end
      user
    end

    def get_ip user
      ignored = ["unaffiliated/#{user.nick}","services."]
      return nil if ignored.include? user.host
      return Resolv.getaddress(user.host)
    rescue Exception #Resolv::Error
      puts "--- ResolvError => #{$!}"
      nil
    end

    def create hash
      unless user = IrcUser.find_by_nick(hash[:nick])
        user = IrcUser.new(hash)
      end
      user
    end

    def length
      @@users.length
    end

    def unique_by_ip
      users = @@users.select{|u|u.ip} # has ip
      users.each do |user|
        users.each do |u|
          users.delete(user) if (user != u) && (user.ip == u.ip)
        end
      end
      users
    end

  end
end

#
# instance api
#

class IrcUser

  attr_accessor :nick, :host, :ip

  def initialize hash

    @nick = hash[:nick]
    @host = hash[:host]
    @ip   = IrcUser.get_ip(self)

    @@users << self unless @@hidden.include?(hash[:nick])

  end

  def hostmask
    "#{@nick}@#{@ip}"
  end

end

