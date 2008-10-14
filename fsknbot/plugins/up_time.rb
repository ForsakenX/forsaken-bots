class UpTime < Irc::Plugin
  def pre_init
    @commands = [:uptime]
  end
  def uptime m
    output = `uptime`
    output =~ /^.* ([0-9]+ days).*$/m
    m.reply $1 || output
  end
end
