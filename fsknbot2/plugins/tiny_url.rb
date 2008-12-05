require 'tinyurl'
IrcCommandManager.register 'tinyurl', 'tinyurl <url>... => shrinks url' do |m|
  results = []
  m.args.each do |url|
    t = Tinyurl.new(url)
    results << "{ #{t.tiny} => #{t.original} }"
  end
  m.reply results.join(", ")
end
