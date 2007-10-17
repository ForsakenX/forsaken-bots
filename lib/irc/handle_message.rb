class Irc::HandleMessage

  def initialize(client,line)

    case line

    # IRCD says fatal error
    when /^ERROR/i
      exit

    # ping
    when /^PING ([^\n]*)$/i
      client.send_data "PONG #{$1}\n"

    # login completed
    when /^:[^ ]* 001 /i
      # join default channels
      client.join client.config['channels']

    # set nick succeeded
    # :_0_fskn_games!1000@c-68-36-237-152.hsd1.nj.comcast.net NICK :_1_fskn_games
    when /^:[^ ]+![^@]*@[^ ]* NICK [:]*([^ ]*)/i
      nick = $1
      client.nick = nick

    # set nick failed
    when /^:[^ ]* 433 /i
      client.send_nick "#{client.nick_sent}_"

    # motd
    when /^:[^ ]* (375|372|376)/

    # channel topic
    when /^[^ ]* 332/

    # names list but we use who list instead
    when /^[^ ]* (353|366)/

    # 1st whois line (start)
      # :koolaid.ny.us.blitzed.org 311 _0_fskn_games Silence
      # FUHQ c-24-63-156-24.hsd1.ma.comcast.net * :BLABLA

    # 2nd whois line
    # :koolaid.ny.us.blitzed.org 319 _0_fskn_games Silence :#kahn
    when /^[^ ]* 319 [^ ]* ([^ ]*) [:]*([^ \n]*)/
      nick = $1
      channel = $2
      # find user
      user = Irc::User.find(client.server,nick)
      # join them to the channel
      user.join channel

    # 3rd whois line
      # :koolaid.ny.us.blitzed.org 312 _0_fskn_games Silence
      #  cookies.on.ca.blitzed.org :C is for c00kie eh?

    # 4th whois line (end)
    # :koolaid.ny.us.blitzed.org 318 _0_fskn_games Silence :End of /WHOIS list.
    when /^[^ ]* 318/

    # who responses
    # a single user in who list
      # :koolaid.ny.us.blitzed.org 352 _0_fskn_games #kahn
      #  FUHQ c-24-63-156-24.hsd1.ma.comcast.net 
      #  cookies.on.ca.blitzed.org Silence H :2 BLABLA
    when /:([^ ]*) 352 [^ ]* (#[^ ]*) ([^ ]*) ([^ ]*) [^ ]* ([^ ]*) ([^:]* :[^ ]*) ([\n]*)/i

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

    # end of who list
    when /:[^ ]* 315/

    # someone joins a chat
    when /:[^ ]* JOIN/
      m = Irc::JoinMessage.new(client,line)

    # part
    when /:[^ ]* PART/i
      m = Irc::PartMessage.new(client,line)

    # quit
    when /:[^ ]* QUIT/i
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
