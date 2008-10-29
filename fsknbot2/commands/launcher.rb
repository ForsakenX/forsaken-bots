
IrcCommandManager.register 'launcher', 'link to launcher' do |m|
    db = "#{ROOT}/db/launcher.link"
    url = File.read(db).gsub("\n","")
    m.reply "You can download the new launcher "+
             "from the following url: { #{url} }."
end

