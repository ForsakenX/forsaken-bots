
IrcCommandManager.register 'urls',
"urls => Prints last few urls seen in channel.  "+
"urls <[-]words> => Search on all words and remove those prefixed with '-'.  "+
"urls last => Return the last url seen.  "+
"urls count => Return the count of saved urls.  "+
"urls list => Link to the whole database."

IrcCommandManager.register 'urls' do |m|
  m.reply UrlCommand.run(m)
end

IrcChatMsg.register do |m|
  UrlCommand.message(m)
end

require 'timeout'
require 'mechanize'
class UrlCommand 
  class << self
  
    @@agent = WWW::Mechanize.new
    @@agent.user_agent_alias = "Linux Mozilla"
    @@agent.read_timeout = 3 # fuck you
    @@agent.keep_alive = false # http keepalives

    @@db_path = "#{ROOT}/db/urls.yaml"
    @@db = File.expand_path(@@db_path)
    @@urls = (File.exists?(@@db) && YAML.load_file(@@db)) || []

    @@response_codes = {
      "404" => "Page not found"
    }

    #
    #  Command
    #  

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

    #
    #  Listener
    #
  
    def message m
      return unless m.channel
      words = m.message.split(' ')
      urls = words.find_all{|p| p =~ /^((https?:\/\/|www\.).+)/im; $1 }
      urls.each{|u| check_url(m,u) }
      save
    end

    def check_url m, url
      url = "http://#{url}" unless url =~ /^http/
      # try to get page 3 times
      page = ""
      n = 3
      n.times do |i|
        begin
          page = @@agent.get(url)
          break
        rescue Timeout::Error
          throw Timeout::Error if i == (n-1)
        end
      end
      info = handle_page(m,url,page)
      # delete last entry for this url
      @@urls.dup.each{|u| @@urls.delete u if u[0] == url }
      # save the url
      @@urls.unshift [url,info,m.from.nick,m.to,m.time]
    rescue WWW::Mechanize::RedirectLimitReachedError
      m.reply "To many redirects for: #{url}"
    rescue WWW::Mechanize::ResponseCodeError
      if error = @@response_codes[$!.response_code]
        m.reply error
      else
        m.reply "Unhandeled response code: #{$!.response_code}"
      end
    rescue WWW::Mechanize::UnsupportedSchemeError
      m.reply "Unsupported Scheme: #{$!.scheme}"
    rescue WWW::Mechanize::ContentTypeError
      m.reply "ContentType Error: #{$!.content_type}"
    rescue Exception
      m.reply "Error Inspecting URL: #{$!}"
      puts_error __FILE__,__LINE__
    end

    def handle_page(m,url,page)
      info = nil
      if !page.respond_to?(:title)
        info = link_info(m,url,page)
      elsif page.title.nil? || page.title.gsub(/\s+/,'').empty?
        m.reply "Title is missing."
      else
        info = page.title
        # one time printed entire set of links on page
        # protect by cutting down to 200 chars
        m.reply "[Link Title]: #{info.slice(0,200)}"
      end
      info
    end

    def link_info m,url,page
# need way to get final url or response['file-name']
      #url.request_uri =~ /\/([^\/\?]+)$/
      url =~ /\/([^\/\?]+)$/
      filename = $1
      if length = page.response['content-length']
        length = format_size(length)
      end
      info  = "[Link Info]: "+
              "filename: '#{filename||'unknown'}', "+
              "size: (#{length||0}), "+
              "content-type: (#{page.response['content-type']}), "+
              "last-modified: (#{page.response['last-modified']})"
      m.reply info
      info
    end

    def format_size bytes
      n = bytes.to_f
      sizes = %w{B KB MB GB}
      i = 0
      n /= 1024.0 while (n > 1024) && (i += 1) < sizes.length
      n = (n*100.0).round/100.0
      "#{n} #{sizes[i]}"
    end
  
    def save
      file = File.open(@@db,'w+')
      YAML.dump(@@urls,file)
      file.close
    end

  end
end
