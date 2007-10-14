  # handles a part message
  class Irc::PartMessage < Irc::Message
    attr_accessor :user
    def initialize(client,line)
      super(client,line)

      # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #kahn
      # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PART #tester
      unless line =~ /:([^!]*)!([^@]*)@([^ ]*) PART [:]*(#[^\n]*)$/i
        puts "Error: badly formed PART message"
        return
      end

      nick     = $1
      user     = $2
      host     = $3
      channel  = $4

      # add or update user
      if @user = Irc::User.find(nick)
=begin must setup Channel class first
        @user.update({:channel => channel, :user => user,
                      :host    => host,    :nick => nick})
      else
        @user = User.create({:channel => channel, :user => user,
                             :host    => host,    :nick => nick})
      end
=end
        @user.destroy

        @client._part(self)
      end
    end
  end


