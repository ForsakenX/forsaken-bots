
IrcCommandManager.register 'urls',
"urls => Prints last few urls seen in channel.  "+
"urls <[-]words> => Search on all words and remove those prefixed with '-'.  "+
"urls last => Return the last url seen.  "+
"urls count => Return the count of saved urls.  "+
"urls list => Link to the whole database."

IrcCommandManager.register 'urls' do |m|
  m.reply UrlCommand.run m
end

IrcChatMsg.register do |m|
  UrlCommand.chat_listener m
end

require 'mechanize'
class UrlCommand 
  class << self
 
    @@db_path = "#{ROOT}/db/urls.yaml"
    @@db = File.expand_path(@@db_path)
    @@urls = (File.exists?(@@db) && YAML.load_file(@@db)) || []

    def save
      file = File.open(@@db,'w+')
      YAML.dump(@@urls,file)
      file.close
    end

    def run m
      case m.args.first
      when "last"
        last m
      when "count"
        count m
      when nil
        urls m
      when "list"
        "http://fly.thruhere.net/status/urls.txt"
      else
        search m
      end
    end
  
    def count m
      "There are #{@@urls.length} urls."
    end
  
    def last m
      u = @@urls.first
      "#{u[2]}: #{u[1]} => #{u[0]}"
    end
  
    def search m
      urls = @@urls
      # for each search word
      while needle = m.args.shift
        # unmatch
        needle.slice!(1,needle.length) if (unmatch = (needle[0] == '-'[0]))
        # find urls that match
        urls = urls.find_all do |url|
          # if needle is found in search fields
          fields = url[0..2].join(' ').downcase
          includes = fields.include?(needle.downcase)
          unmatch ? !includes : includes
        end
      end
      # any found?
      return "Your search did not return any results..." if urls.empty?
      # format output
      urls = urls.map{|url| "#{url[2]}: #{url[1]} => #{url[0]}" }
      # only show top results
      urls[0..1].join(', ')
    end
  
    def urls m
      return "There is no urls yet..." if @@urls.empty?
      urls = @@urls[0..3].map do |url|
        "#{url[2]}: #{url[1]} => #{url[0]}"
      end
      urls.join(', ')
    end

    def chat_listener m
      return unless m.channel
      words = m.message.split(' ')
      urls = words.find_all{|p| p =~ /^((https?:\/\/|www\.).+)/im; $1 }
      urls.each do |url|
        # get the page data
        begin
          # one time this printed entire set of links on page
          # protect by cutting down to 200 chars
          info = Url.describe_link( url ).slice!(0,200)
          m.reply info
        rescue Exception
          m.reply $!
          next # do not save
        end
        # delete last entry for this url
        @@urls.dup.each{|u| @@urls.delete u if u[0] == url }
        # save the url
        @@urls.unshift [url,info,m.from.nick,m.to,m.time]
      end
      # save the database
      save
    end

  end
end


class Url
  class << self
 
    @@agent = WWW::Mechanize.new
    @@agent.user_agent_alias = "Linux Mozilla"
    @@agent.read_timeout = 3 # fuck you
    @@agent.keep_alive = false # http keepalives

    @@response_codes = {
      "404" => "Page not found"
    }

    def describe_link url
      page = get( url )
      title = link_title( url, page )
      if title.empty?
        "[Link Info]: #{link_info( url, page )}"
      else
        "[Link Title]: #{title}"
      end
    end

    # get page handle
    def get url, n = 3 # default 3 attempts
      url = "http://#{url}" unless url =~ /^http/
      n.times do |i|
        begin
          return @@agent.get(url)
          break # success
        rescue Timeout::Error
          throw Timeout::Error if i == (n-1)
        end
      end
    rescue WWW::Mechanize::RedirectLimitReachedError
      throw "To many redirects for: #{url}"
    rescue WWW::Mechanize::ResponseCodeError
      if error = @@response_codes[$!.response_code]
        throw error
      else
        throw "Unhandeled response code: #{$!.response_code}"
      end
    rescue WWW::Mechanize::UnsupportedSchemeError
      throw "Unsupported Scheme: #{$!.scheme}"
    rescue WWW::Mechanize::ContentTypeError
      throw "ContentType Error: #{$!.content_type}"
    rescue Timeout::Error
      throw "Timed out trying to connect."
    rescue Exception
      puts_error __FILE__,__LINE__
      throw "Error Inspecting URL: #{$!}"
    end

    # get title of page
    def link_title url, page=nil
      page = get(url) if page.nil?
      return "" unless page.respond_to? :title
      return "" if page.title.nil?
      page.title.gsub!(/\s+/,' ')
    end

     # get link info
    def link_info url, page=nil
      page = get(url) if page.nil?
# need way to get final url or response['file-name']
      #url.request_uri =~ /\/([^\/\?]+)$/
      url =~ /\/([^\/\?]+)$/
      filename = $1
      if content_length = page.response['content-length']
        length = format_size(content_length)
      end
      "filename: '#{filename||'unknown'}', "+
      "size: (#{length||0}), "+
      "content-type: (#{page.response['content-type']}), "+
      "last-modified: (#{page.response['last-modified']})"
    end

    def format_size bytes
      n = bytes.to_f
      sizes = %w{B KB MB GB}
      i = 0
      n /= 1024.0 while (n > 1024) && (i += 1) < sizes.length
      n = (n*100.0).round/100.0
      "#{n} #{sizes[i]}"
    end

  end
end


