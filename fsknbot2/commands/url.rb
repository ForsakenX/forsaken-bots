
IrcCommandManager.register 'urls',
"urls => Prints last few urls seen in channel.  "+
"urls [words] => Search url history.  "+
"urls last => Return the last url seen.  "+
"urls count => Return the count of saved urls."

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
    @@agent.read_timeout = 2 # fuck you
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
      needle = m.args.join(' ')
      urls = @@urls.find_all {|url|
                             fields = url[0..2].join(' ').downcase
                             fields.include?(needle.downcase)
                            }.map{|url|
                             "#{url[2]}: #{url[1]} => #{url[0]}"
                            }
      return "Your search did not return any results..." if urls.empty?
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
      page = @@agent.get(url)
      title = if page.respond_to?(:title)
        handle_html_page(m,url,page)
      else
        handle_non_html_page(m,url,page)
      end
      # delete last entry for this url
      @@urls.dup.each{|u| @@urls.delete u if u[0] == url }
      # save the url
      @@urls.unshift [url,title,m.from.nick,$channel,m.time]
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

    def handle_html_page(m,url,page)
      if page.title
        #HTMLEntities.decode_entities
        #html_unescape (WWW::Mechanize::Util)
        m.reply "[Link Title]: #{page.title}"
        page.title
      else
        m.reply "Page title is missing."
        #url.request_uri =~ /\/([^\/\?]+)$/
        url =~ /\/([^\/\?]+)$/
        filename = $1
        #if length = @@agent.headers['content_length']
        #  length format_size(length)
        #end
        info = "filename: #{filename}"
        #info += ", size: (#{length})" unless length.nil?
      end
    end

    def handle_non_html_page m,url,page
      m.reply page.response['content-length']
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
