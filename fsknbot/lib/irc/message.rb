# handles a message
class Irc::Message

  include Irc::MessageHelpers

  attr_reader :client, :line, :time

  def initialize(client,line,time)
    @client = client
    @line   = line
    @time   = time
  end

end
