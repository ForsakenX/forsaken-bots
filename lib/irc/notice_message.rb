 
  # handles a notice message
  class Irc::NoticeMessage < Irc::Message
    def initialize(client, line)
      super(client, line)
      @client._notice(self)
    end
  end

