

IrcCommandManager.register 'learn',
"learn <target> is <definition> => Teaches the bot." do |m|
  m.reply WhatCommand.learn(m)
end

IrcCommandManager.register 'what',
"what is <target> => Define <target> " do |m|
  m.reply WhatCommand.what(m)
end

IrcCommandManager.register 'forget',
"forget <target> => Tells the bot to unlearn something." do |m|
  m.reply WhatCommand.forget(m)
end

IrcCommandManager.register 'learned',
"learned => Prints list of known <targets>" do |m|
  m.reply WhatCommand.learned(m)
end

class WhatCommand
  class << self

    @@db_path = File.expand_path("#{ROOT}/db/what.yaml")
    @@db = File.exists?(@@db_path) ? (YAML.load_file(@@db_path)||{}) : {}
    @@url = "http://fly.thruhere.net/status/what.txt"

    def learned m
      "I've learned #{@@db.keys.length} topics: #{@@url}"
    end
  
    def what m
      if m.args.shift.downcase != "is" || m.args.length < 1
        return "syntax: what is <something>"
      end
      target  = m.args.join(' ')
      unless translation = @@db[target]
        return "I don't know what #{target} is."
      end
      "#{target}: #{translation}"
    end
  
    def forget m
      return "forget <target>" if m.args.length < 1
      @@db.delete m.args.shift
      save
      "Forgotten."
    end
  
    def learn m
      unless m.args.join(' ') =~ /(.*) is (.*)/i && $1 && $2
        return "learn <target> is <something>"
      end
      @@db[$1] = $2
      save
      "Done."
    end
  
    def save
      file = File.open(@@db_path,'w+')
      YAML.dump(@@db,file)
      file.close
    end
  
  end
end
