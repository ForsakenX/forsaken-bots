class Irc::PartMessage < Irc::Message
  attr_reader :user, :channel
  def initialize(client,line)
    super(client,line)

    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #kahn
    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #tester
    # :Deadly_Methods!22510264@68.36.237.152 PART #GSP!forsaken :
    unless line =~ /:([^!]*)![^@]*@[^ ]* PART (#[^ ]+)/i
      @client.logger.error "Badly formed PART message: #{line}"
      return
    end

    #
    nick    = $1
    @channel = $2

    # remove user from channel
    @user.leave(@channel) if @user = Irc::User.find(client.server,nick)
      
    # notify client
    @client.event.call('irc.message.part',self)

  end
end
