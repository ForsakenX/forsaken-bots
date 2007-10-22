class Irc::UnknownMessage < Irc::Message
  def initialize(client, line)
    super(client, line)
    @client.event.call('irc.message.unknown',self)
  end
end
