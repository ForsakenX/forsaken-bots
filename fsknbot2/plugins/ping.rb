
IrcCommandManager.register 'ping',
"ping => Ping everyone in the chat.  "+
"ping block => Blocks your name from showing up on a ping event.  "+
"ping unblock => Removes your name from the block list."

IrcCommandManager.register 'ping' do |m|
  m.reply "#{PingCommand.run(m)}"
end

class PingCommand
  class << self

    @@db = File.expand_path("#{ROOT}/db/ping_blocked.yaml")

    def run m

      blocked = list

      case m.args.first
      when 'block'
        blocked << m.from.nick.downcase
        save blocked.uniq
        "You have been blocked"
      when 'unblock'
        blocked.delete(m.from.nick.downcase)
        save blocked.uniq
        "You have been unblocked."
      else
        blocked << m.from.nick.downcase
        users = IrcUser.nicks.map{|n|blocked.index(n.downcase)?nil:n}.compact
        "(FsknBot2) " + users.sort.join(', ')
      end

    end

    def list
      (FileTest.exists?(@@db) && YAML.load_file(@@db)) || []
    end

    def save blocked
      file = File.open(@@db,'w+')
      YAML.dump(blocked,file)
      file.close
    end

  end
end
