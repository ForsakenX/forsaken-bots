
IrcCommandManager.register 'uptime', 'server uptime' do |m|
  output = `uptime`
  output =~ /^.* ([0-9]+ days).*$/m
  m.reply $1 || output
end

