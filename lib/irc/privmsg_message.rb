# handles a priv message
class Irc::PrivMessage < Irc::Message

  def type; "PRIVMSG"; end

  attr_accessor :replyto, :channel, :source, :message, :to, :personal

  # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG MethBot :,hi 1 2 3
  # :methods!1000@c-68-36-237-152.hsd1.nj.comcast.net PRIVMSG #tester :MethBot: hi 1 2 3
  # :Deadly_Methods!*@* PRIVMSG #GSP!Forsaken :ip
  def initialize(client, line)
    super(client, line)

    # working copy
    _line = line.dup

    # :
    # garbage
    _line.slice!(/^:/)

    # methods!1000@c-68-36-237-152.hsd1.nj.comcast.net 
    # Deadly_Methods!*@* PRIVMSG #GSP!Forsaken :ip
    # source
    @source = nil
    source = _line.slice!(/[^ ]*/)
    # PRIVMSG #GSP!Forsaken :ip
    if source =~ /([^!]*)!([^@]*)@([^\n]*)/
      user = $2
      host = $3
      nick = $1
      # do we know this user allready?
      unless @source = Irc::User.find(nick) # has more information
        # create a mock user
        @source = Irc::User.new({:user   => user,
                                 :host   => host,
                                 :nick   => nick })
      end
    end

    # " PRIVMSG "
    # #GSP!Forsaken :ip
    # garbage
    _line.slice!(/ #{type} /)

    # "(MethBot|#tester)"
    # #GSP!Forsaken :ip
    # where this _line came from
    @to = _line.slice!(/^[^ ]*/)

    # channel _line ?
    @channel = (@to =~ /^#/) ? @to : nil

    # personal _line ?
    @personal = @channel ? false : true

    # replyto
    @replyto = nil
    if @channel
      @replyto = @channel
    else
      @replyto = @source.nil? ? nil : @source.nick
    end

    # channel object
    @channel = client.channels[@channel.downcase] if @channel

    # " :"
    # ip
    # garbage
    _line.slice!(/ :/)

    # ",hi 1 2 3"
    # "MethBot: hi 1 2 3"
    # the rest is the message
    @message = _line

  end

end
