
IrcCommandManager.register 'welcome',
"welcome list => List messages.  "+
"welcome show <message> => Show a message."
"welcome add|edit <name> <message> => Adds a message."

IrcCommandManager.register 'welcome' do |m|
  WelcomeCommand.command m
end

IrcHandleLine.events[:join].register do |nick|
  WelcomeCommand.join nick.downcase
end

class WelcomeCommand
  class << self

    @@db_dir = "#{ROOT}/db/welcomes"

    def join nick
      return if nick == $nick # don't send messages to our selves
      return if IrcUser.hidden nick
      welcome_files.each do |file|
        path = db_path( file )
        db = load_yaml( path )
        unless db.include? nick
          db << nick
          save path, db
          IrcConnection.privmsg nick, read(file+".txt")
          return
        end
      end
    end

    def command m
      case m.args.shift
      when 'list'
        m.reply "messages => "+welcome_files.sort.join(', ')
      when 'show'
        if welcome_files.include? m.args.first
          m.reply "#{m.args.first} => "+ read("#{m.args.first}.txt")
        else
          m.reply "Unknown message"
        end
      when 'add','edit'
        return m.relpy("You are not authorized") unless m.from.authorized?
        f = File.open("#{@@db_dir}/#{m.args.shift}.txt",'w+')
        f.write m.args.join(' ')
        f.close
        m.reply "Welcome message has been created."
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
      File.read("#{@@db_dir}/#{file}").gsub("\n",' ')
    end

    def welcome_files
      list.map{|w|File.basename(w.sub(/.txt$/,''))}
    end

    def list
      Dir[ @@db_dir + "/*.txt" ]
    end

  end
end

