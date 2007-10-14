 
  # handles unknown messages
  class Irc::UnknownMessage < Irc::Message
    def initialize(client, line)
      super(client, line)
      @client._unknown(self)
    end
  end

