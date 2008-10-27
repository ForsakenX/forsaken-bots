class HandleMessage < Irc::Plugin

  def listen line

    time = Time.now
  
    case line

    #
    #  Nick Changes
    #

    # :methods!n=daquino@c-68-36-237-152.hsd1.nj.comcast.net NICK :ype
    when /^:([^!]+)[^ ]* NICK :([^ ]+)$/i

      old_nick = $1
      new_nick = $2

      # fsknbot never changes his name
      next if @bot.nick.downcase == old_nick.downcase

      # update nick
      if user = Irc::User.find(old_nick)
        user.nick = new_nick
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
      m = Irc::TopicMessage.new(@bot,line,time)
      @bot.event.call('irc.message.topic',m)

    when /^:[^ ]* JOIN/
      m = Irc::JoinMessage.new(@bot,line,time)
      @bot.event.call('irc.message.join',m)

    when /^:[^ ]* PART/i
      m = Irc::PartMessage.new(@bot,line,time)
      @bot.event.call('irc.message.part',m)

    when /^:[^ ]* QUIT/i
      m = Irc::QuitMessage.new(@bot,line,time)
      @bot.event.call('irc.message.quit',m)

    when /^:[^ ]* KICK/i
      m = Irc::KickMessage.new(@bot,line,time)
      @bot.event.call('irc.message.kick',m)

    when /^:[^ ]* PRIVMSG/i
      m = Irc::PrivMessage.new(@bot,line,time)
      @bot.event.call('irc.message.privmsg',m)
    
    when /^:[^ ]* NOTICE/i
      m = Irc::NoticeMessage.new(@bot,line,time)
      @bot.event.call('irc.message.notice',m)

    end
  end
end
