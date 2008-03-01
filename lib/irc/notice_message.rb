# nothing differen't from privmsg
class Irc::NoticeMessage < Irc::PrivMessage
  def type; "NOTICE"; end
end
