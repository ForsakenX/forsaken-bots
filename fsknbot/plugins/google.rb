require 'cgi'
require 'uri'
require 'net/http'
require 'rubygems'
require 'htmlentities'
class Google < Client::Plugin
  @@wap_search = "http://www.google.com/wml/search?hl=en&q="
  @@wap_news_search = "http://news.google.com/wml/search?hl=en&q="
  @@wap_link   = /<a accesskey="(\d)" href=".*?u=(.*?)">(.*?)<\/a>/im
  @@results = 3
  def initialize *args
    super *args
    @bot.command_manager.register("!google",self)
    @bot.command_manager.register("google",self)
    @bot.command_manager.register("search",self)
    @bot.command_manager.register("news",self)
    @bot.command_manager.register("wp",self)
    @bot.command_manager.register("youtube",self)
  end
  def help(m=nil, topic=nil)
    "google|search <search> => Return top #{@@results} results from google.com.  "+
    "news <search> => Return top #{@@results} results from news.google.com.  "+
    "wp <search> => Return #{@@results} results from WikiPedia.  "+
    "Examples: google toyota  " +
    "NOTE: <search> is passed unmodified to google"
  end
  def command m
    if m.command == "google"
      m.reply "Start using !google because google gets in the way of talking about google..."
      return false
    end
    if (query = m.params.join(' ')).empty?
      return false
    end
    query = "#{query} site:wikipedia.org" if m.command == "wp"
    query = "#{query} site:youtube.com" if m.command == "youtube"
    begin
      search   = (m.command == "news") ? @@wap_news_search : @@wap_search
      url      = URI.parse(search+CGI.escape(query))
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
      formated = results[0...@@results].map {|result|
        number = result[0]
        url    = URI.unescape(result[1])
        title  = HTMLEntities.decode_entities(result[2].strip)
        "(#{number}) #{title} #{url}"
      }
      m.reply "Results: #{formated.join("  ")}"
    rescue Exception
      m.reply "Error: (#{$!})"
      LOGGER.error "(#{$!}):\n#{$@.join("\n")}"
      return
    end
  end
end
