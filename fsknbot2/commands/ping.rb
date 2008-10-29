IrcCommandManager.register 'ping', 'pongs' do |m|
  m.reply "(FsknBot2) #{IrcUser.nicks.sort.join(', ')}"
end
