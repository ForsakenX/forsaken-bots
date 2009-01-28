
IrcCommandManager.register 'uptime' do |m|
  m.reply `uptime`.split('up ')[1].split(',')[0]
end

