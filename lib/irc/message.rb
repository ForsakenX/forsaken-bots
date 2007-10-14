# handles a message
class Irc::Message
  attr_accessor :client, :line
  def initialize(client,line)
    @client = client
    @line   = line
    @client._listen(self)
  end
end
