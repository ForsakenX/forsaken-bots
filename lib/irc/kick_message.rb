class Irc::KickMessage < Irc::Message
  attr_accessor :admin, :user, :channel, :message
  def initialize(client,line)
    super(client,line)

    # :methods!n=daquino@c-68-36-237-152.hsd1.nj.comcast.net
    # KICK #forsaken DIII-The_Lion :methods
    unless line =~ /:([^ ]*)![^@]*@[^ ]* KICK (#[^ ]*) ([^ ]*) *:*([^\n]*)/i
      client.logger.error "Bad Kick message..."
      return
    end

    kicker   = $1
    @channel = $2
    kicked   = $3
    @message = $4
    
    unless @admin = Irc::User.find(client.server,kicker)
      @client.logger.info "[KICK] Kicker was not found..."
    end

    unless @user = Irc::User.find(client.server,kicked)
      @client.logger.error "[KICK] Kicked was not found..."
    else
      @user.destroy
    end

    @client.event.call('irc.message.kick',self)

  end
end
