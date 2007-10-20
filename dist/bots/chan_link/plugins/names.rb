class Names < Meth::Plugin
  def help m=nil
    "names => Sends you a list of names on all linked channels."
  end
  def command m
    output = ""
    Irc::Client.clients.each do |name,client|
      output += "Server: #{client.server[:host]} => "
      output += client.users.map{|user|"#{user.nick}"}.join(', ')
    end
    m.reply "A list of users has been messaged to you."
    m.reply_directly output
  end
end
