
module Irc::Helpers

  def channels
    Irc::Channel.channels
  end

  def say to, message
    # return if @ignored.include?(to.downcase)
    message = message.to_s if message.respond_to?(:to_s)
    return message unless message
    # for each line
    message.split("\n").each do |message|
      # send at chunks of 350 characters
      # scan up to extra 50 non space characters
      # biggest word in english language is 45 characters
      # this stops worsd from getting cut up
      message.scan(/.{1,350}[^ ]{0,50}/m){|chunk|
        next if chunk.length < 1
        send_data "PRIVMSG #{to} :#{chunk}\n"
      }
    end
    send_data "\n"
    message
  end

  def send_join channels
    return if channels.nil?
    channels = channels.split(' ') if channels.is_a? String
    channels.each do |channel|
     send_data "JOIN #{channel.to_s}\n"
    end
  end

  def send_nick nick=nil
    unless nick.nil?
      @nick_sent = nick
      send_data "NICK #{nick}\n"
    end
  end

end

