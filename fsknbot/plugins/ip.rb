class Ip < Client::Plugin

  include DirectPlay

  def initialize *args
    super *args
    @bot.command_manager.register("ip",self)
  end

  def help m=nil,topic=nil
    "ip [patterns] => "+
      "Get ip addresses of users in the channel. "+
      "Optional [patterns] that match user names.  "+
      "Leave blank to get all addresses."
  end

  def command m

    #
    targets = m.params

    # output holder
    list = []

    # users
    users = m.channel ? m.channel.users : [m.source]

    # get and format list of found addresses
    Irc::User.filter(users,targets).each do |user|
      #next if user.ip.nil?
      if user.ip.nil?
        list << "#{user.nick} => http://www.lemonparty.org"
        next
      end
      list << "{ #{user.nick} => #{user.ip} }"
    end

    list = list.join(', ')

    # send the answer


    if m.personal || targets.length > 0
      m.reply list
    else
      m.reply "A full list of ip numbers from #{m.channel.name} has been messaged to you."
      m.reply_directly list
    end

  end

end

