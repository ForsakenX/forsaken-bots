
IrcCommandManager.register 'ping',
"ping => Ping everyone in the chat.  "+
"ping block => Blocks your name from showing up on a ping event.  "+
"ping unblock => Removes your name from the block list."

IrcCommandManager.register 'ping' do |m|
  m.reply "(FsknBot2): #{PingCommand.run(m)}"
end

class PingCommand
  class << self

    @@db = File.expand_path("#{ROOT}/db/ping_blocked.yaml")

    def run m

      blocked = list

      case m.args.first
      when 'block'
        blocked << m.from.nick
        save blocked.uniq
        "You have been blocked"
      when 'unblock'
        blocked.delete(m.from.nick)
        save blocked.uniq
        "You have been unblocked."
      else
        users = IrcUser.nicks
        blocked.each { |user| users.delete(user) }
        users.sort.join(' ')
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
