
# helpers for Irc::Message
module Irc::MessageHelpers

  def reply message
    return unless instance_variable_defined?(:@replyto)
    @client.msg @replyto, message
  end

  def reply_directly message
    return unless instance_variable_defined?(:@source)
    @client.msg @source.nick, message
  end

  def reply_notice message
    return unless instance_variable_defined?(:@replyto)
    @client.notice @replyto, message
  end

end

