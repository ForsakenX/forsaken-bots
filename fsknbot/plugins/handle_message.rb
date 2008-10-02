class HandleMessage < Irc::Plugin

  def listen args
  
    client, line, time = args

    case line

    # set nick succeeded
      # :hostname NICK :methods
    when /^:([^ ]+)![^@]*@[^ ]* NICK [:]*([^ ]*)/i
      old_nick = $1
      new_nick = $2

      # someone else changed their nick
      if nick.downcase != old_nick.downcase
        if user = Irc::User.find(old_nick)
          user.nick = new_nick
        end
      end

    # who lines
    # a single user in who list
      # :koolaid.ny.us.blitzed.org 352 _0_fskn_games #kahn
      #  FUHQ c-24-63-156-24.hsd1.ma.comcast.net 
      #  cookies.on.ca.blitzed.org Silence H :2 BLABLA
    when /^:([^ ]*) 352 [^ ]* (#[^ ]*) ([^ ]*) ([^ ]*) [^ ]* ([^ ]*) ([^:]* :[^ ]*) ([\n]*)/

      server   = $1 # server
      channel  = $2 # in channel
      user     = $3 # uid
      host     = $4 # hostname
      nick     = $5 # irc nick
      flags    = $6 # irc flags
      realname = $7 # MethBot

      # add or update user
      if u = Irc::User.find(nick)
        u.join channel
        u.flags = flags
      else
        u = Irc::User.create({
              :channels => [channel],
              :user   => user,          :host     => host,
              :nick   => nick,          :flags    => flags,
              :realname => realname})
      end

    when /^:[^ ]* (332|TOPIC)/i
      m = Irc::TopicMessage.new(client,line,time)
      client.event.call('irc.message.topic',m)

    when /^:[^ ]* JOIN/
      m = Irc::JoinMessage.new(client,line,time)
      client.event.call('irc.message.join',m)

    when /^:[^ ]* PART/i
      m = Irc::PartMessage.new(client,line,time)
      client.event.call('irc.message.part',m)

    when /^:[^ ]* QUIT/i
      m = Irc::QuitMessage.new(client,line,time)
      client.event.call('irc.message.quit',m)

    when /^:[^ ]* KICK/i
      m = Irc::KickMessage.new(client,line,time)
      client.event.call('irc.message.kick',m)

    when /^:[^ ]* PRIVMSG/i
      m = Irc::PrivMessage.new(client,line,time)
      client.event.call('irc.message.privmsg',m)
    
    when /^:[^ ]* NOTICE/i
      m = Irc::NoticeMessage.new(client,line,time)
      client.event.call('irc.message.notice',m)

    end
  end
end
