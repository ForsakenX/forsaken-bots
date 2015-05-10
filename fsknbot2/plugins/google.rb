
IrcCommandManager.register ['google','g'], 'google <search>' do |m|
  m.reply GoogleCommand.run(m)
end

IrcCommandManager.register ['news','n'], 'news <topic>' do |m|
  m.reply GoogleNewsCommand.run(m)
end

IrcCommandManager.register ['wiki','w'], 'wiki <search>' do |m|
  m.reply GoogleCommand.desc(m.args.join(' '))
end

IrcCommandManager.register ['define','d'], 'define <word>' do |m|
  m.reply GoogleCommand.define(m.args.join(' '))
end

require 'mechanize'
require 'cgi'
class GoogleCommand
  class << self
    @@max_results = 3
    @@agent = Mechanize.new
    @@page = @@agent.get('http://google.com')
    @@form = @@page.form_with(:name => 'f')
	def parse_serp_links result
		#result.links.select{|l|l.attributes['class']=='l'}
		#result.links.select{|l| l.attributes['class'].nil? and !l.attributes['onmousedown'].nil? }
		result.links.
			select{|l| l.href =~ %r{^/url\?q=} }.
			select{|l| l.href !~ %r{/settings/ads/} }
	end
	def desc query
		query = "site:wikipedia.org #{query}"
    form = @@form.dup
    form.q = query
    result = form.submit
		links = parse_serp_links result
		return "No results found" if links.empty?
		link = GoogleLink.parse links.first.href
		parser = result.parser
		#content = parser.search('div.s').first
		content = parser.search('div.s .st').first
		return "No results found" if content.nil?
		#content.css('cite, span.gl, span.vshid').each { |n| n.remove }
		content.content + " #{link}"
	end
	def define query
		query = "site:wiktionary.org #{query}"
	  form = @@form.dup
	  form.q = query
	  result = form.submit
		links = parse_serp_links result
		return "No results found" if links.empty?
		link = GoogleLink.parse links.first.href
		parser = result.parser
		content = parser.search('div.s .st').first
		return "No results found" if content.nil?
		content.content + " #{link}"
	end
    def run m
      query = m.args.join(' ')
      return m.reply("Missing search") if query.empty?
      count = 0
      links = search( query )
      return "No results found" if links.empty?
      formatted = ""
      links[0..(@@max_results-1)].each do |link|
        t = GoogleLink.parse( link.href )
        r = "(#{count+=1}) #{link.text} #{t}"
        # keep limited to one line of irc
        break if formatted.length + r.length > 230
        formatted += "#{r} "
      end
      "Results: #{formatted}"
    end
    def search query
      form = @@form.dup
      form.q = query
      result = form.submit
			parse_serp_links result
    end
  end
end

require 'uri'
require 'rss'
class GoogleNewsCommand
  class << self

    @@max_results = 3
    @@search = "http://www.google.com/news"+
               "?hl=en&ned=us&q=[[query]]&ie=UTF-8&nolr=1&output=rss"

    def run m
      search m.args.join(' ')
    end

    def search query
      count = 0
      formatted = ""
      parsed = parse(query)
      return "Query failed" if parsed.nil?
      items = parsed.items
      return "No results found" if items.nil? or items.empty?
      items[0..(@@max_results-1)].each do |item|
        link = GoogleLink.parse(item.link.split('url=')[1])
        title = Mechanize::Util::html_unescape( item.title )
        r = "(#{count+=1}) #{title} #{link}"
        # keep limited to one line of irc
        break if formatted.length + r.length > 230
        formatted += "#{r} "
      end
      "Results: #{formatted}"
    end

    def url query
      query = URI.escape query
      @@search.sub('[[query]]',query)
    end

    def parse query
      rss = RSS::Parser.parse(url(query))
    rescue RSS::InvalidRSSError
      RSS::Parser.parse(url(query),false)
    end

  end
end

class GoogleLink
  class << self
    def parse url
			url = extract_url url
      return url if url.length < 40
      t = TinyUrl.new( url )
      t.tiny || t.original
    end
		def extract_url url
			CGI::unescape url.split('q=')[1].split('&')[0]
		end
  end
end

