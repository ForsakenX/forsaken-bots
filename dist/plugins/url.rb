require 'net/http'
require 'htmlentities'
require 'timeout'
class Url < Meth::Plugin
  def pre_init
    @bot.command_manager.register("urls",self)
    @bot.command_manager.register("links",self)
    @db = File.expand_path("#{BOT}/db/urls.yaml")
    @urls = (File.exists?(@db) && YAML.load_file(@db)) || []
  end
  def help(m=nil, topic=nil)
    "urls => Prints last 3 urls pasted in channel.  "+
    "urls [search] <needle> => Search for <needle in links."
  end
  def command m
    if m.command == "links"
      m.reply "`links' is deprecated please use `urls' instead."
    end
    if m.params[0].nil?
      urls m
    else
      search m
    end
  end
  def search m
    m.params.join(' ') =~ /(search ){0,1}([^ ]*)/
    needle = $2
    urls = @urls.find_all {|url|
                           (url[0]+url[1]).downcase.include?(needle.downcase)
                          }.map{|url|
                           "#{url[2]}: #{url[1]} => #{url[0]}"
                          }
    if urls.empty?
      m.reply "Your search did not return any results..."
      return
    end
    if urls.length > 5
      urls = urls[(urls.length-5-1)..(urls.length-1)]
    end
    m.reply urls.join(', ')
  end
  def urls m
    if @urls.empty?
      m.reply "There is no urls yet..."
      return
    end
    if @urls.length <= 3
      urls = @urls
    else
      urls = @urls[(@urls.length-3-1)..(@urls.length-1)]
    end
    urls = urls.map do |url|
      "#{url[2]}: #{url[1]} => #{url[0]}"
    end
    m.reply urls.join(', ')
  end
  def privmsg m
    words = m.message.split(' ')
    urls = words.find_all{|p| p =~ /^((http:\/\/|www\.).+)/m; $1 }
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
      @urls << [url,info,m.source.nick,(m.channel.name if m.channel),Time.now]
    end
    save
  end
  def get_info m, url
    begin

      # handle a http response
      handle_response = Proc.new{|response|
        # check http response type
        unless [ Net::HTTPOK,
                 Net::HTTPPartialContent
               ].include?(response.class)
          raise "url did not return http-ok:  "+
                "(#{response.class}) (#{url})" \
        end

        # get html title
        if response.content_type == "text/html"
          buffer = ""
          response.read_body do |segment|
            if (buffer += segment) =~ /<title>([^<]*)<\/title>/i
              if $1.nil? || $1.empty?
                m.reply "The title was empty."
              else
                title = HTMLEntities.decode_entities($1)
                title.gsub!(/\s+/,' ')
                title = title.strip
                return "title: #{title}"
              end
            end
          end
          # if we make it here there was an issue reading the title
          m.reply "Title could not be extracted."
        end

        # adhoc
        # for when no title's
        url.request_uri =~ /\/([^\/\?]+)$/
        filename = $1
        length = response.content_length.nil? ?
                 nil :
                 format_size(response.content_length)
        info = "filename: #{filename}"
        into += ", size: (#{length})" unless length.nil?

        return info

      }

      # prepare net/http
      url      = URI.parse(url)
      http     = Net::HTTP.new(url.host, url.port)

      time = Time.now
      begin
        # stop if http does not answer in 2 seconds
        Timeout.timeout(2){
          # request the uri
          http.request_get(url.request_uri){|response|
            handle_response.call(response)
          }
        }
      rescue Timeout::Error
        raise "http response timeout (#{Time.now-time})"
      end

      raise "This message shouldn't be printed."

    rescue Exception
      @bot.logger.error "Url: (#{$!}):\n#{$@.join("\n")}"
      m.reply $!
      return nil
    end
  end
  private
  def format_size bytes
    clean = bytes
    dirty = 0
    count = 0
    size  = %w{B KB MB}
    while (clean > 1024) && ((count += 1) > 2)
      dirty = clean % 1024
      clean = clean / 1024
    end
    "#{clean}.#{dirty} #{size[count]}"
  end
  def save
    file = File.open(@db,'w+')
    YAML.dump(@urls,file)
    file.close
  end
end
