class Irc::JoinMessage < Irc::Message

  attr_reader :user

  def initialize(client, line)
    super(client, line)

    # joined
    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net JOIN :#kahn
    unless line =~ /:([^ ]*)!([^@]*)@([^ ]*) JOIN :(#[^\n]*)$/i
      throw "Bad JOIN message..."
    end

    nick     = $1
    user     = $2
    host     = $3
    channel  = $4

    # We have joined a chat
    if client.nick == nick
      # get a list of users for channel
      client.send_data "WHO #{channel}\n"
    else
      # get more details on the user
      client.send_data "WHOIS #{nick}\n"
    end

    # add or update user
    if @user = Irc::User.find(nick)
      @user.update({:channel => channel, :user => user,
                    :host    => host,    :nick => nick})
    else
      @user = Irc::User.create({:channel => channel, :user => user,
                                 :host    => host,    :nick => nick})
    end

    # call user space
    @client._join(self)

  end

end


