class Irc::QuitMessage < Irc::Message
  attr_accessor :user, :message
  def initialize(client,line)
    super(client,line)

    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net QUIT :Quit: Leaving.
    # :MethBot_!1000@c-68-36-237-152.hsd1.nj.comcast.net QUIT :Client closed connection
    # :Krez!i=RJFJE@cpc1-ledn1-0-0-cust990.leed.cable.ntl.com QUIT :
    # :methods!n=daquino@c-68-36-237-152.hsd1.nj.comcast.net QUIT :"Leaving."
    # :Deadly_Methods!22510264@68.36.237.152 QUIT :FUCKING WORK!
    unless line =~ /:([^ ]*)![^@]*@[^ ]* QUIT *:*([^\n]*)/i
      client.logger.error "Bad QUIT message..."
    end

    # nick
    nick     = $1
    @message = $2

    # add or update user
    if @user = Irc::User.find(nick)
      @user.destroy
    else
      @client.logger.error "[QUIT] but user was not found..."
    end

    # call client
    @client.event.call('irc.message.quit',self)

  end
end
