class Irc::PartMessage < Irc::Message
  attr_reader :user, :channel, :message
  def initialize(client,line)
    super(client,line)

    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #kahn
    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #tester
    # :Deadly_Methods!22510264@68.36.237.152 PART #GSP!forsaken :
    # :Deadly_Methods!22510264@68.36.237.152 PART #GSP!forsaken :blow me
    unless line =~ /:([^!]*)![^@]*@[^ ]* PART (#[^ ]+) :*([^\n]*)$/i
      @client.logger.error "Badly formed PART message: #{line}"
      return
    end

    #
    nick     = $1
    channel = $2
    @message = $3

    # channel object
    @channel = client.channels[channel.downcase]
    
    # remove user from channel
    @user.leave(@channel.name) if @user = Irc::User.find(nick)
      
  end
end
