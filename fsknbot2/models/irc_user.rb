require 'resolv'

#
# Public API
#

class IrcUser
  class << self

    @@authorized = %w{methods silence diii-the_lion}
    def authorized; @@authorized; end

    @@hidden = %w{chanserv epsy ski.* ntrek.*}
    @@hidden << $nick

    @@users = []; def users; @@users; end

    def authorized? nick
      not @@authorized.detect{|hostmask| nick =~ /#{hostmask}/i }.nil?
    end

    def hidden nick
      not @@hidden.detect{|hostmask| nick =~ /#{hostmask}/i }.nil?
    end

    def find_by_nick nick
      return false if nick.nil? || nick.empty?
      @@users.detect{|u| u.nick.downcase == nick.downcase }
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

    def nicks
      @@users.map{|u|u.nick}
    end

  end
end

#
# instance api
#

class IrcUser

  attr_accessor :nick
  attr_reader :host, :ip, :ignored

  def initialize hash

    @nick    = hash[:nick]
    @host    = hash[:host]
    @ip      = IrcUser.get_ip(self)
    @ignored =  IrcUser.hidden(hash[:nick])

    @@users << self

  end

  def hostmask
    "#{@nick}@#{@ip}"
  end

  def authorized?
    IrcUser.authorized? self.nick
  end

end

