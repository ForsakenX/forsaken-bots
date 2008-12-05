

IrcCommandManager.register 'hi' do |m|
  m.reply `ruby -Ku #{ROOT}/plugins/_hi.rb`
end

