require 'tinyurl'
class VersionCatcher < Meth::Plugin

  # @version = { :url => '', :tinyurl => '', :number => '', :time => '' }

  def pre_init
    @commands = [:version]
    @db = File.expand_path("#{BOT}/db/version.yaml")
    @version = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
  end

  def version m
    time = @version[:time].strftime("%m/%d/%y %H:%M:%S")
    m.reply "Current Version #{@version[:number]} "+
            "#{@version[:tinyurl]} "+
            "updated on #{time} "
  end

  def privmsg m
    return unless authorized?(m.source.nick.downcase)
    words = m.message.split(' ')
    urls = words.find_all{|p| p =~ /^((https?:\/\/|www\.).+)/im; $1 }
    urls.each do |url|
      next unless url =~ /ProjectX_([0-9\.]+)(_Executable)?\.zip/
      unless valid_version($1)
        m.reply "Bad version number: (#{$1})"
        break
      end
      update $1, url
      break
    end
  end

  private

  def update version, url
    update_db version, url
    set_topic version
  end

  def update_db version, url
    t = Tinyurl.new(url)
    @version = {
      :url      => t.original,
      :tinyurl  => t.tiny,
      :number   => version,
      :time     => Time.now
    }
    save
  end

  def valid_version version=""
    !version.empty?
  end

  def authorized? user
    ["silence","methods"].include?(user)
  end

  def set_topic version
    official,user = Irc::Channel.channels['#forsaken'].topic.split('||')
    official.gsub!(/Forsaken: [^ ]+/,"Forsaken: #{version}")
    topic = "#{official}||#{user}"
    cmd = "TOPIC #forsaken :#{topic}\n"
    @bot.send_data(cmd)
  end

  def save
    file = File.open(@db,'w+')
    YAML.dump(@version,file)
    file.close
  end

end
