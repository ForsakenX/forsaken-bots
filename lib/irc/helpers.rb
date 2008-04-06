
module Irc::Helpers

  def channels
    Irc::Channel.channels
  end

  def say to, message
    sender :privmsg, to, message
  end
  alias_method :msg, :say

  def notice to, message
    sender :notice, to, message
  end

  def sender type, to, message
    types = {
      :privmsg => "PRIVMSG",
      :notice  => "NOTICE",
    }
    # return if @ignored.include?(to.downcase)
    message = message.to_s if message.respond_to?(:to_s)
    return message unless message
    # for each line
    message.split("\n").each do |message|
      # can't add up to more than 512 bytes on reciever side
      # this stops worsd from getting cut up
      message.scan(/.{1,280}[^ ]{0,100}/m){|chunk|
        next if chunk.length < 1
        send_data "#{types[type]} #{to} :#{chunk}\n"
      }
    end
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

