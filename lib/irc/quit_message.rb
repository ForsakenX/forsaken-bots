class Irc::QuitMessage < Irc::Message
  attr_accessor :user
  def initialize(client,line)
    super(client,line)

    # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net QUIT :Quit: Leaving.
    # :MethBot_!1000@c-68-36-237-152.hsd1.nj.comcast.net QUIT :Client closed connection
    unless line =~ /:([^ ]*)!([^@]*)@([^ ]*) QUIT ([:]*.*)*$/mi
      @logger.error "Bad QUIT message..."
    end

    # nick
    nick = $1

    # add or update user
    @user.destroy if @user = Irc::User.find(client.server,nick)

    # call client
    @client._quit(self)

  end
end

