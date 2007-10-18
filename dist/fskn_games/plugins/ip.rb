class Ip < Meth::Plugin

  include DirectPlay

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
      list << "#{user.nick} => #{user.ip}"
    end

    list = list.join(', ')

    # send the answer
    if m.personal || targets.length>0
      m.reply list
    else
      puts m.channel.inspect
      m.reply "A full list of ip numbers from #{m.channel.name} has been messaged to you. "+
              "To print the message here you have to specify a search pattern. "+
              "For more info type 'ip help'"
      m.reply_directly list
    end

  end

end

