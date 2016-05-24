require 'duck_duck_go'
IrcCommandManager.register ['ddg','??'], "query duck-duck-go instant answers" do |m|
	begin
		query = m.args.join(' ')
		if query.empty?
			m.reply "Missing input"
		else
			zci = DuckDuckGo.new.zeroclickinfo(query)
			def truncate m; m.length > 150 ? m.slice(/.{1,150}[^ ]{0,50}/m) + " ... " : m; end
			m.reply truncate(zci.abstract_text) rescue puts "ddg abstract_text: #{$!}"
			m.reply truncate(zci.related_topics["_"][0].text) rescue puts "ddg relation: #{$!}"
			m.reply "https://duckduckgo.com/?q=#{query.gsub(/ /,'+')}"
		end
	rescue Exception
		puts_error __FILE__,__LINE__
	end
end
