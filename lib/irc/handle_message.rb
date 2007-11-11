class Irc::HandleMessage

  def initialize(client,line)

    puts "[INPUT] " + line

    case line

    # IRCD says fatal error
    when /^ERROR/i
      client.logger.error "ERROR - Server disconnecting..."

    # ping
    when /^PING ([^\n]*)$/i
      client.send_data "PONG #{$1}\n"

    # login completed
    when /^:[^ ]* 001 /
      # join default channels
      client.send_join client.config['channels']

    # set nick succeeded
      # :_0_fskn_games!1000@c-68-36-237-152.hsd1.nj.comcast.net NICK :_1_fskn_games
      #:tes1!i=1000@c-68-36-237-152.hsd1.nj.comcast.net NICK :methods
    when /^:([^ ]+)![^@]*@[^ ]* NICK [:]*([^ ]*)/i
      old_nick = $1
      new_nick = $2

      # i successfully changed my nick
      if client.nick.downcase == old_nick.downcase
        client.nick = new_nick
      # someone else changed their nick
      else
        puts Irc::User.users.collect{|u|u.nick}.join(', ')
        if user = Irc::User.find(client.server,old_nick)
          user.nick = new_nick
        # this is fine cause multiple bots can share a user list if on same server
        else
          #puts "[ERROR] Got nick change from '#{old_nick}' to '#{new_nick}' but user does not exist..."
        end
      end

    # set nick failed
    when /^:[^ ]* 433 /i
      client.send_nick "#{client.nick_sent}_"

    # motd
    #when /^:[^ ]* (375|372|376)/

    # channel topic
    #when /^[^ ]* 332/
      #client.channels[channel].topic = topic

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
      #user = Irc::User.find(client.server,nick)
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
      if u = Irc::User.find(client.server,nick)
        u.join channel
        u.flags = flags
      else
        u = Irc::User.create({
              :server => client.server, :channels => [channel],
              :user   => user,          :host     => host,
              :nick   => nick,          :flags    => flags,
              :realname => realname})
      end

      # get list of chats the user is in
      #client.send_data "WHOIS #{u.nick}\n"

    # end of who list
    #when /^:[^ ]* 315/

    # someone joins a chat
    when /^:[^ ]* JOIN/
      m = Irc::JoinMessage.new(client,line)

    # part
    when /^:[^ ]* PART/i
      m = Irc::PartMessage.new(client,line)

    # quit
      # :methods!i=1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG #forsaken :i'm quiting
    when /^:[^ ]* QUIT/i
      m = Irc::QuitMessage.new(client,line)

    # privmsg
    when /^:[^ ]* PRIVMSG/i
      m = Irc::PrivMessage.new(client,line)
    
    # notice
    when /^:[^ ]* NOTICE/i
      m = Irc::NoticeMessage.new(client,line)
    
    # unknown
    else
      m = Irc::UnknownMessage.new(client,line)
    end

  end

end
