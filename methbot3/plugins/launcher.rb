IrcCommandManager.register 'launcher', 'link to launcher' do |m|
  m.reply  File.read("#{ROOT}/db/launcher.txt")
end
