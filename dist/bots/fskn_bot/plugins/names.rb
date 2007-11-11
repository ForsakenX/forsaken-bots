class Names < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("names",self)
  end
  def help m=nil
    "names => Sends you a list of names on all linked channels."
  end
  def command m
    hosts = []
    Irc::Client.clients.each do |name,client|
      host = client.server[:host]
      next if hosts.include? host
      hosts << host
      next if host == m.client.server[:host]
      m.reply "#{host}: "+
              client.users.map{|user|"#{user.nick}"}.join(', ')
    end
  end
end
