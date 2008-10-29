IrcCommandManager.register 'topic', 'edits the topic' do |m|
  m.reply TopicCommand.run(m)
end

class TopicCommand
  class << self

    def run m
      case m.args[0]
      when nil,""
        IrcTopic.get
      else
        IrcTopic.set m.args.join(' ')
        "topic changed"
      end
    end

  end
end
