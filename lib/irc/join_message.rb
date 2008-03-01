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
    channel   = $4

    # get a list of users details for channel
    client.send_data "WHO #{channel}\n"

    # get channel mode
    client.send_data "MODE #{channel}\n"

    # add or update user
    if @user = Irc::User.find(nick)
      @user.join(channel)
    else
      @user = Irc::User.create({:channels => [channel], :user => user,
                                :host     => host,      :nick => nick})
    end

    # channel object created on join by user code above
    @channel = @client.channels[channel.downcase]

  end

end
