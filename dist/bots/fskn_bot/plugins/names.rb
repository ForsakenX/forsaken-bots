class Names < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("names",self)
  end
  def help m=nil, topic=nil
    "names => Sends you a list of names on all linked channels."
  end
  def command m
    hosts = Hash.new {|h,k| h[k] = []}
    Irc::Client.clients.each do |name,client|
      host = client.server[:host]
      users = client.users.map{|user|
        # return nil if same host and user in the same channel
        next nil if host == m.client.server[:host] &&
                    m.channel.users.map{|u|u.nick.downcase}.include?(user.nick.downcase)
        # add to list
        "#{user.nick}"
      }
      hosts[host].concat users
    end
    hosts.each do |host,users|
      users = users.uniq.compact
      m.reply "#{host}: " + users.join(', ') if users.length > 0
    end
  end
end
