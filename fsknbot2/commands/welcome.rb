
IrcCommandManager.register 'welcome',
"welcome list => List messages.  "+
"welcome show <message> => Show a message."

IrcCommandManager.register 'welcome' do |m|
  WelcomeCommand.command m
end

IrcHandleLine.events[:join].register do |nick|
  WelcomeCommand.join nick
end

class WelcomeCommand
  class << self

    @@db_dir = "#{ROOT}/db/welcomes"

    def join nick
      return if nick == $nick # don't send messages to our selves
      return if IrcUser.hidden.include? nick
      list_names.each do |file|
        path = db_path( file )
        db = load_yaml( path )
        unless db.include? nick
          db << nick
          save path, db
          IrcConnection.privmsg nick, read(file)
          return
        end
      end
    end

    def command m
      case m.args.shift
      when 'list'
        m.reply "messages => "+list_names.sort.join(', ')
      when 'show'
        if list_names.include? m.args.first
          m.reply "=> "+ read("#{m.args.first}.txt")
        else
          m.reply "Unknown message"
        end
      else
        m.reply "Unknown option: "+IrcCommandManager.help[ 'welcome' ]
      end
    end

    def save file, db
      file = File.open(file,'w+')
      YAML.dump(db,file)
      file.close
    end

    def db_path file
      "#{@@db_dir}/#{file}.yaml"
    end

    def load_yaml path
      File.exists?( path ) ? (YAML.load_file( path )||[]) : []
    end

    def read file
      File.read("#{@@db_dir}/#{file}.txt").gsub("\n",' ')
    end

    def list_names
      list.map{|w|File.basename(w.sub(/.txt$/,''))}
    end

    def list
      Dir[ @@db_dir + "/*.txt" ]
    end

  end
end

