IrcCommandManager.register ['knowledge','k','?'], "query wolfram alpha" do |m|
	begin
		query = m.args.join(' ')
		if query.empty?
			m.reply "Missing input"
		else
			output = WolframAlpha.get_text_result(query)
			output = output.slice(/.{1,150}[^ ]{0,50}/m) if output.length > 150
			output += " ... #{WolframAlpha.browser_url(query)}"
			m.reply output
		end
	rescue Exception
		puts_error __FILE__,__LINE__
	end
end

require 'nokogiri'
require 'open-uri'
require 'cgi'

class WolframAlpha
class << self
	APPID = File.read("#{ROOT}/config/wolfram.appid").strip
	QUERY_URL = "http://api.wolframalpha.com/v1/query?appid=#{APPID}&input="
	def browser_url input
		"http://wolframalpha.com/input/?i=#{CGI.escape input}"
	end
	def query input
		url = QUERY_URL + CGI.escape(input)
		doc = Nokogiri::XML open(url)
		success = doc.css('queryresult').first.attributes['success'].value == "true"
		didyoumean = doc.css('didyoumean').text
		errormsg = doc.css('error msg').text
		return [nil,"Did you mean? " + didyoumean] unless didyoumean.empty?
		return [nil,"Error: " + errormsg] unless errormsg.empty?
		return [nil,"Unknown Error"] unless success
		doc
	end
	def get_text_result input
		result,error = query(input)
		return error if error
		plaintexts = result.css('plaintext')
		return "No plain text response available" if plaintexts.length == 0
		plaintexts.map{|n| n.text }.join('; ')
	end
end
end
