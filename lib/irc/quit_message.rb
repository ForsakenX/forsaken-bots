  # handles a quit message
  class Irc::QuitMessage < Irc::Message
    #:methods!1000@c-68-36-237-152.hsd1.nj.comcast.net QUIT :Quit: Leaving.
    attr_accessor :user
    def initialize(client,line)

      #
      super(client,line)

      # :MethBot_!1000@c-68-36-237-152.hsd1.nj.comcast.net QUIT :Client closed connection
      unless line =~ /:([^ ]*)!([^@]*)@([^ ]*) QUIT ([:]*.*)*$/mi
        throw "Bad QUIT message..."
      end

      # nick
      nick = $1

      # add or update user
      @user.destroy if @user = Irc::User.find(nick)

      @client._quit(self)
    end
  end

