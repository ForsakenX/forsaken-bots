class Names < Meth::Plugin
  def help m=nil
    "names => Sends you a list of names on all linked channels."
  end
  def command m
    Irc::Client.clients.each do |name,client|
      m.reply_directly "#{client.server[:host]}: "+
                       client.users.map{|user|"#{user.nick}"}.join(', ')
    end
    m.reply "A list of users has been messaged to you." unless m.personal
  end
end
