class Irc::NoticeMessage < Irc::Message
  def initialize(client, line)
    super(client, line)
    @client.event.call('irc.message.notice',self)
  end
end
