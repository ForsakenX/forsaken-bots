class UpTime < Meth::Plugin
  def pre_init
    @commands = [:uptime]
  end
  def uptime m
    `uptime` =~ /^.* ([0-9]+ days).*$/m
    m.reply $1
  end
end
