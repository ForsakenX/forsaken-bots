class HandleMessage < Irc::Plugin

  def listen client, line, time

    case line

    # IRCD says fatal error
    when /^ERROR/i
      LOGGER.error "ERROR - Server disconnecting..."

    # ping
    when /^PING ([^\n]*)$/i
      send_data "PONG #{$1}\n"

    # login completed
    when /^:[^ ]* 001/
      # join default channels
      send_join @client.default_channels

    # set nick succeeded
      # :hostname NICK :methods
    when /^:([^ ]+)![^@]*@[^ ]* NICK [:]*([^ ]*)/i
      old_nick = $1
      new_nick = $2

      # i successfully changed my nick
      if nick.downcase == old_nick.downcase
        nick = new_nick
      # someone else changed their nick
      else
        if user = Irc::User.find(old_nick)
          user.nick = new_nick
        end
      end

    # set nick failed
    when /^:[^ ]* 433 /i
      send_nick "#{nick_sent}_"

    # motd
    #when /^:[^ ]* (375|372|376)/

    ##
    # 1st whois line (start)
    ##

    # 1st whois line (start)
    # WHO does this
      # :koolaid.ny.us.blitzed.org 311 _0_fskn_games Silence
      # FUHQ c-24-63-156-24.hsd1.ma.comcast.net * :BLABLA
    #when /^[^ ] 311 [^ ]* ([^ ]*) ([^ ]*) ([^ ]*) [^ ]* [:]*([^\n ]*)/

    # 2nd whois line
      # if you see @# means your in same room as this person
      # :zelazny.freenode.net 319 _MethBot chino
      # :#what #crack #meth #ruby-lang @#forsaken
    #when /^[^ ]* 319 [^ ]* ([^ ]*) [:]*(.*)/m
      #nick = $1
      # list of channels the user is in
      #channels = "#{$2}".gsub('@','').split(' ')
      # find user
      #user = Irc::User.find(nick)
      # join them to the channel
      #channels.each do |channel|
      #  user.join channel
      #end

    # 3rd whois line
    # WHO does this
      # :koolaid.ny.us.blitzed.org 312 _0_fskn_games Silence
      #  cookies.on.ca.blitzed.org :C is for c00kie eh?
    #when /^[^ ]* 312 [^ ]* ([^ ]*) [^ ]* /

    # 4th whois line (end)
    # WHO does this
      # :koolaid.ny.us.blitzed.org 318 _0_fskn_games Silence :End of /WHOIS list.
    #when /^[^ ]* 318/

    # names list
    # WHO does this
    #when /^[^ ]* (353|366)/

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

      # get list of chats the user is in
      #send_data "WHOIS #{u.nick}\n"

    # end of who list
    #when /^:[^ ]* 315/

    # mode responses
      # :ChanServ!ChanServ@services. MODE #projectx +o methods
      # :kornbluth.freenode.net 324 FsknBot #forsaken +tncz
      # :kornbluth.freenode.net 329 FsknBot #forsaken 1192567839
    when /^:[^ ]* 324 [^ ]* (#[^ ]*) ([^ ]*)/
      channel = $1
      mode    = $2

      if channel = channels[channel.downcase]
        channel.mode = mode
      else
        LOGGER.warn "[324] unknown channel."
      end

    when /^:[^ ]* (332|TOPIC)/i
      m = Irc::TopicMessage.new(client,line,time)
      @client.event.call('irc.message.topic',m)

    when /^:[^ ]* JOIN/
      m = Irc::JoinMessage.new(client,line,time)
      @client.event.call('irc.message.join',m)

    when /^:[^ ]* PART/i
      m = Irc::PartMessage.new(client,line,time)
      @client.event.call('irc.message.part',m)

    when /^:[^ ]* QUIT/i
      m = Irc::QuitMessage.new(client,line,time)
      @client.event.call('irc.message.quit',m)

    when /^:[^ ]* KICK/i
      m = Irc::KickMessage.new(client,line,time)
      @client.event.call('irc.message.kick',m)

    when /^:[^ ]* PRIVMSG/i
      m = Irc::PrivMessage.new(client,line,time)
      @client.event.call('irc.message.privmsg',m)
    
    when /^:[^ ]* NOTICE/i
      m = Irc::NoticeMessage.new(client,line,time)
      @client.event.call('irc.message.notice',m)

    end
  end
end
