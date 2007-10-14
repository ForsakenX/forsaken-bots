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
      client.join client.channels

    # set nick failed
    when /^:[^ ]* 433 /i
      client.send_nick "#{client.nick_sent}_"

    # motd
    when /^:[^ ]* (375|372|376)/

    # channel topic
    when /^[^ ]* 332/

    # names list but we use who list instead
    when /^[^ ]* (353|366)/

    # who responses
    # a single user in who list
    when /:([^ ]*) 352 [^ ]* (#[^ ]*) ([^ ]*) ([^ ]*) [^ ]* ([^ ]*) ([^:]* :[^ ]*) ([\n]*)/i

      server   = $1 # server
      channel  = $2 # in channel
      user     = $3 # uid
      host     = $4 # hostname
      nick     = $5 # irc nick
      flags    = $6 # irc flags
      realname = $7 # MethBot

      # add or update user
      if u = Irc::User.find(nick)
        u.update({:server => server, :channel => channel,
                  :user   => user,   :host    => host,
                  :nick   => nick,   :flags   => flags,
                  :realname => realname})
      else
        u = Irc::User.create({:server => server, :channel => channel,
                         :user   => user,   :host    => host,
                         :nick   => nick,   :flags   => flags,
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
