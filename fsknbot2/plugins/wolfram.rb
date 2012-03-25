IrcCommandManager.register ['knowledge','k','?'], "query wolfram alpha" do |m|
	begin
		query = m.args.join(' ')
		if query.empty?
			m.reply "Missing input"
		else
			m.reply WolframAlpha.get_text_result(query)
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
	def query input
		url = QUERY_URL + CGI.escape(input)
		doc = Nokogiri::XML open(url)
		success = doc.css('queryresult').first.attributes['success'].value == "true"
		success = doc.css('queryresult').first.attributes['success'].value == "true"
		didyoumean = doc.css('didyoumean').text
		return [nil,"Did you mean? " + didyoumean] unless didyoumean.empty?
		return [nil,doc.css('error msg').text] unless success
		doc
	end
	def get_text_result input
		result,error = query(input)
		return error if error
		text = result.css('plaintext').map{|n|n.text.empty? ? nil : n.text}.compact.join('; ')
		return "No plain text response available" if text.empty?
		text
	end
end
end
