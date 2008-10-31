
require 'irc_chat_msg'
IrcChatMsg.register do |m|
  VersionCatcherCommand.message(m)
end

IrcCommandManager.register 'version',
'version [format|list] => info on forsaken versions' do |m|
  m.reply VersionCatcherCommand.run(m)
end

require 'yaml'
require 'tinyurl'
class VersionCatcherCommand
  class << self

    # model of a version
    # @version = { :url => '', :tinyurl => '', :number => '', :time => '' }

    @@db = File.expand_path("#{ROOT}/db/versions.yaml")
    @@format = "(ProjectX_([0-9\.]+)-([^.]+)\.zip)";

    def run m
      case m.args.shift
      when 'list'
        versions
      when 'format'
        @@format
      else
        version
      end
    end

    def db
      File.exists?(@@db) ? (YAML.load_file(@@db)||{}) : {}
    end
  
    def version
      release = db['release']
      return "No official releases yet..." unless release
      time = release[:time].strftime("%m/%d/%y %H:%M:%S")
      "New Release: #{release[:number]} #{time} @ "+
      "#{release[:tinyurl]} OR #{release[:url]}"
    end
  
    def versions
      return "No versions stored yet..." if db.empty?
      output = []
      db.each do |build,version|
        time = version[:time].strftime("%m/%d/%y %H:%M:%S")
        output << "{ #{version[:build]} - "+
                    "#{version[:number]} @ "+
                    "#{version[:tinyurl]} from "+
                    "#{time} }"
      end
      output.join(', ')
    end
  
    def message m
      return unless authorized?(m.from.nick)
      words = m.message.split(' ')
      urls = words.find_all{|w| w =~ /^(https?:\/\/.+)/im; w }
      urls.each do |url|
        next unless url =~ /#{@@format}/
        update $1, $2, $3, url
        return m.reply "Saved: { version => #{$2}, build => #{$3} }"
      end
    end
  
    def update filename, version, build, url
      t = Tinyurl.new(url)
      list = db
      list[ build ] = {
        :url      => t.original,
        :tinyurl  => t.tiny,
        :number   => version,
        :time     => Time.now,
        :filename => filename,
        :build    => build
      }
      save list
      set_topic(version) if build == 'release'
    end
  
    def authorized? user
      ["silence","methods"].include?(user)
    end
  
    def set_topic version
      official,user = IrcTopic.get.split('||')
      if official.gsub!(/Forsaken: [^ ]+/i,"Forsaken: #{version}")
        IrcConnection.topic "#{official}||#{user}"
      end
    end
  
    def save list
      update_xml list
      file = File.open(@@db,'w+')
      YAML.dump(list,file)
      file.close
    end
  
    def update_xml list
      doc = REXML::Document.new
      v = doc.add_element("versions")
      list.each do |build,version|
        v.add_element("version",{
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
end
