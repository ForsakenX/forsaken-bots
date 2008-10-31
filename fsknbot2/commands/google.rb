
IrcCommandManager.register ['google','wiki','youtube'], 'google <search>' do |m|
  m.reply GoogleCommand.run(m)
end

=begin
  require 'rubygems'
  require 'mechanize'

  a = WWW::Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
  }

  a.get('http://google.com/') do |page|
    search_result = page.form_with(:name => 'f') do |search|
      search.q = 'Hello world'
    end.submit

    search_result.links.each do |link|
      puts link.text
    end
  end
=end

require 'cgi'
require 'uri'
require 'net/http'
require 'rubygems'
require 'htmlentities'

class GoogleCommand
  class << self

    @@results = 3
    @@wap_search = "http://www.google.com/wml/search?hl=en&q="
    @@wap_link   = /<a accesskey="(\d)" href=".*?u=(.*?)">(.*?)<\/a>/im
  
    def run m
  
      return false if (query = m.args.join(' ')).empty?
  
      query = "#{query} site:wikipedia.org" if m.command == "wiki"
      query = "#{query} site:youtube.com" if m.command == "youtube"

      search query

   end

   def search query
  
      url      = URI.parse( @@wap_search + CGI.escape(query) )
      http     = Net::HTTP.new(url.host, url.port)
      response = http.request(Net::HTTP::Get.new(url.request_uri))
   
      return "Sorry, Google is acting up..." unless check_response(response)

      results = response.body.scan(@@wap_link)

      return "No results found for: #{query}" if results.length == 0

      formated = results[0...@@results].map {|result|
        number = result[0]
        url    = URI.unescape(result[1])
        title  = HTMLEntities.decode_entities(result[2].strip)
        "(#{number}) #{title} #{url}"
      }

      "Results: #{formated.join("  ")}"

    rescue Exception
      puts_error __FILE__,__LINE__
    end

    def check_response response
      Net::HTTPOK === response ||
      Net::HTTPPartialContent === response ||
      response.body
    end

  end
end
