# handles a message
class Irc::Message
  attr_accessor :client, :line
  def initialize(client,line)
    @client = client
    @line   = line
    @client.event.call('irc.message.listen',self)
  end
end
