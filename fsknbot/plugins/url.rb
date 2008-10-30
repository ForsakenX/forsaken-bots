require 'net/http'
require 'htmlentities'
require 'timeout'
class Url < Irc::Plugin
  def pre_init
    @bot.command_manager.register("urls",self)
    @bot.command_manager.register("url",self)
    @db = File.expand_path("#{ROOT}/db/urls.yaml")
    @urls = (File.exists?(@db) && YAML.load_file(@db)) || []
  end
  def help(m=nil, topic=nil)
    "urls => Prints last 3 urls pasted in channel.  "+
    "urls [search] <needle> => Return last 5 links that match <needle>.  "+
    "url last => Return the last url detected.  "+
    "url count => Return the count of saved urls.  "
  end
  def command m
    case m.command
    when "links"
      m.reply "`links' is deprecated please use `urls' instead."
    when "url"
      do_url m
    when "urls"
      do_urls m
    end
  end
  def do_url m
    @params = m.params
    case @params.shift
    when "last"
      last m
    when "count"
      count m
    end
  end
  def do_urls m
    if m.params[0].nil?
      urls m
    else
      search m
    end
  end
  def count m
    m.reply "There are #{@urls.length} urls."
  end
  def last m
    last = @urls.first
    m.reply "#{last[2]}: #{last[1]} => #{last[0]}"
  end
  def search m
    m.params.join(' ') =~ /(search ){0,1}([^ ]*)/
    needle = $2
    urls = @urls.find_all {|url|
                           fields = url[0..2].join(' ').downcase
                           fields.include?(needle.downcase)
                          }.map{|url|
                           "#{url[2]}: #{url[1]} => #{url[0]}"
                          }
    if urls.empty?
      m.reply "Your search did not return any results..."
      return
    end
    m.reply urls[0..1].join(', ')
  end
  def urls m
    if @urls.empty?
      m.reply "There is no urls yet..."
      return
    end
    urls = @urls[0..3].map do |url|
      "#{url[2]}: #{url[1]} => #{url[0]}"
    end
    m.reply urls.join(', ')
  end
  def privmsg m
    words = m.message.split(' ')
    urls = words.find_all{|p| p =~ /^((https?:\/\/|www\.).+)/im; $1 }
    urls.each do |url|
      url = "http://#{url}" unless url =~ /^http/
      next if (info = get_info(m, url)).nil?
      m.reply "[Link Info]: #{info}"
      # delete last entry for this url
      @urls.dup.each do |_url|
        next unless _url[0] == url
        @urls.delete _url
      end
      # save the url
      channel = m.channel.nil? ? nil : m.channel.name
      @urls.unshift [url,info,m.source.nick,channel,Time.now]
    end
    save
  end
  def get_info m, url, recursion = -1
    info = ""
    if (recursion += 1) == 20
      m.reply "To many recursions"
      return nil
    end
    begin

      # handle a http response
      handle_response = Proc.new{|response|

#        @bot.msg('methods',response.class.name);

        # check http response type
        case response.class.name
        when "Net::HTTPOK"
        when "Net::HTTPPartialContent"
        when "Net::HTTPForbidden"
          m.reply "The requested url is forbidden..."
          return nil
        when "Net::HTTPMovedPermanently", #301
             "Net::HTTPFound", # 302
             "Net::HTTPSeeOther" # 303
          location = response.header["Location"]
          if response.class.name == "Net::HTTPSeeOther"
            location = "http://#{url.host}:#{url.port}#{location}"
          end
          if location.nil?
            m.reply "Site responded with 301, 302 or 303.  "+
                    "But did not provide a new Location."
            return nil
          end
          info = get_info(m,location,recursion)
          return info
        else
          raise "url did not return http-ok:  "+
                "(#{response.class}) (#{url})" \
        end

        # get html title
        if response.content_type == "text/html"
          buffer = ""
          response.read_body do |segment|
            buffer += segment
            if buffer =~ /<title ?[^>]*>([^<]*)<\/title>/i
              if $1.nil? || $1.empty?
                m.reply "The title was empty."
                break
              else
                title = HTMLEntities.decode_entities($1)
                title.gsub!(/\s+/,' ')
                title = title.strip
                return "title: #{title}"
              end
            end
            if buffer =~ /<\/head>/
              m.reply "Did not see title before </head>"
              break
            end
          end
          # if we make it here there was an issue reading the title
          m.reply "Title could not be extracted."
        end

        # adhoc
        # for when no title's
        if info.empty?
          url.request_uri =~ /\/([^\/\?]+)$/
          filename = $1
          length = response.content_length.nil? ?
                   nil :
                   format_size(response.content_length)
          info = "filename: #{filename}"
          info += ", size: (#{length})" unless length.nil?
        end

        # 
        info += ", #{recursion} redirects" unless recursion == 0
        return info

      }

#      @bot.msg('methods',url);

      # prepare net/http
      url      = URI.parse(url)
      http     = Net::HTTP.new(url.host, url.port)

      count = 3
      loop do
        begin
          # stop if http does not answer in 2 seconds
          Timeout.timeout(2){
            # request the uri
            http.request_get(url.request_uri,{"User-Agent"=>"FsknBot"}){|response|
              handle_response.call(response)
            }
          }
          # get out of loop
          break
        rescue Timeout::Error
          # do loop x times
          count -= 1
          raise "Server did not respond within 3 tries..." if count <= 0
        end
      end

      raise "This message shouldn't be printed."

    rescue Exception
      puts "Url: (#{$!}):\n#{$@.join("\n")}"
      m.reply $!
      return nil
    end
  end
  private
  def format_size bytes
    n = bytes.to_f
    sizes = %w{B KB MB GB}
    i = 0
    n /= 1024.0 while (n > 1024) && (i += 1) < sizes.length
    n = (n*100.0).round/100.0
    "#{n} #{sizes[i]}"
  end
  def save
    file = File.open(@db,'w+')
    YAML.dump(@urls,file)
    file.close
  end
end
