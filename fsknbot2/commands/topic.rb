
IrcCommandManager.register 'topic',
"topic => Show current. "+
"topic last => Show last setter and 4 lines of context. "+
"topic <message> => Reset topic to <message>.  "+
"topic < <message> => Preppends <message>.  "+
"topic > <message> => Appends <message>.  "+
"topic r <find> <replace> => Replace <find> with <replace>.  "


IrcCommandManager.register 'topic' do |m|
  TopicCommand.run(m)
end

IrcChatMsg.register do |m|
  TopicCommand.message(m)
end

class TopicCommand
  class << self
  
    @@buffer      = []
    @@last_buffer = []
    @@last        = nil
    @@last_time   = nil
  
    def message m
      @@buffer.push m.from.nick+": "+ m.message
      @@buffer[3] == nil
      @@buffer = @@buffer.compact
    end
  
    def run m
  
      # only in channel
      return unless m.channel
  
      # show topic
      if (topic = m.args.join(' ')).empty?
puts 1
        return m.reply IrcTopic.get
      end
   
      # last command
      if topic.split.first == "last"
        return last(m)
      end
  
      # save last topic setter
      @@last_buffer = @@buffer.dup
      @@last = m.from.nick
      @@last_time = m.time
  
      # parse the switch if any
      topic.slice!(/^(r|>|<) /)

      # handle the switch
      rv = case $1
      when "r"
        find_replace topic
      when ">"
        IrcTopic.append topic
      when "<"
        IrcTopic.prepend_user topic
      when "",nil
        IrcTopic.set_user topic 
      end
  
    end

    def last m
      m.reply "Topic Setter Was:  #{@@last} "+
              "@ #{@@last_time.strftime('%a %b %d %I:%M %p %Z')}"  
      @@last_buffer.each do |line|
        m.reply_directly line
      end
    end

    def find_replace topic
      if (topic = topic.split).length < 2
        return "Error: Missing <find> or <replace>. "+
               IrcCommandManager.help[ 'topic' ]
      end
      find    = topic.shift
      replace = topic.join(' ')
      IrcTopic.set_user IrcTopic.get_user.sub( find, replace )
    end

  end
end

