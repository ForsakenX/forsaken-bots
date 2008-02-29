# handles a message
class Irc::Message

  include Irc::MessageHelpers

  attr_reader :client, :line, :time

  def initialize(client,line)
    @client = client
    @line   = line
    @time   = Time.now
  end

end
