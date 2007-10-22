class Irc::JoinMessage < Irc::Message

  attr_reader :user, :channel

  def initialize(client, line)
    super(client, line)

    # joined
    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net JOIN :#kahn
    unless line =~ /:([^ ]*)!([^@]*)@([^ ]*) JOIN :(#[^\n]*)$/i
      client.logger.error "Bad JOIN message: #{line}"
      return
    end

    nick      = $1
    user      = $2
    host      = $3
    @channel  = $4

    # get a list of users for channel
    client.send_data "WHO #{channel}\n"

    # add or update user
    if @user = Irc::User.find(client.server,nick)
      @user.join(@channel)
    else
      @user = Irc::User.create({:server   => client.server,
                                :channels => [@channel], :user => user,
                                :host     => host,      :nick => nick})
    end

    # call user space
    @client._join(self)

  end

end


