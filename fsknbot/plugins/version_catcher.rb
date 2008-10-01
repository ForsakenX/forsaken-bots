require 'tinyurl'
class VersionCatcher < Meth::Plugin

  # @version = { :url => '', :tinyurl => '', :number => '', :time => '' }

  def pre_init
    @commands = [:versions,:version,:version_format]
    @db = File.expand_path("#{ROOT}/db/versions.yaml")
    @versions = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
    @format = "(ProjectX_([0-9\.]+)-([^.]+)\.zip)"
  end

  def version_format m
    m.reply @format
  end

  def version m
    release = @versions['release']
    unless release
      m.reply "No official releases yet..."
      return
    end
    time = release[:time].strftime("%m/%d/%y %H:%M:%S")
    m.reply   "New Release: "+
              "#{release[:number]} @ "+
              "#{release[:tinyurl]} from "+
              "#{time} "
  end

  def versions m
    if @versions.empty?
      m.reply "No versions stored yet..."
      return
    end
    output = []
    @versions.each do |build,version|
      time = version[:time].strftime("%m/%d/%y %H:%M:%S")
      output << "{ #{version[:build]} - "+
                  "#{version[:number]} @ "+
                  "#{version[:tinyurl]} from "+
                  "#{time} }"
    end
    m.reply(output.join(', '))
  end

  def privmsg m
    return unless authorized?(m.source.nick.downcase)
    words = m.message.split(' ')
    urls = words.find_all{|p| p =~ /^((https?:\/\/|www\.).+)/im; $1 }
    urls.each do |url|
      next unless url =~ /#{@format}/
      update $1, $2, $3, url
      m.reply "Saved: { version => #{$2}, build => #{$3} } "+
              "Type, 'versions' for a list of known versions..."
      break
    end
  end

  def update filename, version, build, url
    t = Tinyurl.new(url)
    @versions[ build ] = {
      :url      => t.original,
      :tinyurl  => t.tiny,
      :number   => version,
      :time     => Time.now,
      :filename => filename,
      :build    => build
    }
    save
    set_topic(version) if build == 'release'
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
    update_xml
    file = File.open(@db,'w+')
    YAML.dump(@versions,file)
    file.close
  end

  def update_xml
    doc = REXML::Document.new
    versions = doc.add_element("versions")
    @versions.each do |build,version|
      versions.add_element("version",{
        "name" => version[:filename],
        "url"  => version[:url],
        "tinyurl" => version[:tinyurl],
        "number"  => version[:number],
        "time"    => version[:time],
        "filename" => version[:filename],
        "build"    => version[:build]
      })
    end
    # dump to file...
    path = File.expand_path("#{ROOT}/db/versions.xml")
    file = File.open( path, 'w+' )
    file.write doc
    file.close
  end

end
