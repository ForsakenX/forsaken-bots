

IrcCommandManager.register 'hi' do |m|
  m.reply `ruby -Ku #{ROOT}/commands/_hi.rb`
end

