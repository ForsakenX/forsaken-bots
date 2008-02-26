require 'cgi'
require 'uri'
require 'net/http'
require 'rubygems'
require 'htmlentities'
class Google < Meth::Plugin
  @@wap_search = "http://www.google.com/wml/search?hl=en&q="
  @@wap_link   = /<a accesskey="(\d)" href=".*?u=(.*?)">(.*?)<\/a>/im
  def initialize *args
    super *args
    @bot.command_manager.register("!google",self)
    @bot.command_manager.register("google",self)
    @bot.command_manager.register("search",self)
    @bot.command_manager.register("wp",self)
  end
  def help(m=nil, topic=nil)
    "google|search [site:<domain>] <data> => Return top 5 results from google.  "+
    "wp <data> => Return 5 results from WikiPedia.  "+
    "[site:<domain>] limits the domain to search (.com, cars.com).  "+
    "Examples: (google toyota), (google site:cars.com toyota), (wp computer)."
  end
  def command m
    if m.command == "google"
      m.reply "Start using !google because google gets in the way of talking about google..."
      return false
    end
    query = m.params.join(' ')
    query = "site:wikipedia.org #{query}" if m.command == "wp"
    begin
      url      = URI.parse(@@wap_search+CGI.escape(query))
      http     = Net::HTTP.new(url.host, url.port)
      response = http.request(Net::HTTP::Get.new(url.request_uri))
      raise "Sorry, Google is acting up..." unless Net::HTTPOK === response ||
                                                   Net::HTTPPartialContent === response ||
                                                   response.body
      results = response.body.scan(@@wap_link)
      if results.length == 0
        m.reply "No results found for: #{query}"
        return false
      end
      formated = results[0...5].map {|result|
        number = result[0]
        url    = URI.unescape(result[1])
        title  = HTMLEntities.decode_entities(result[2].strip)
        "(#{number}) #{title} #{url}"
      }
      m.reply "Results: #{formated.join("  ")}"
    rescue Exception
      m.reply "Error: (#{$!})"
      @bot.logger.error "(#{$!}):\n#{$@.join("\n")}"
      return
    end
  end
end
