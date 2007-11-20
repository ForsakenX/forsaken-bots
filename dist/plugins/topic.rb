class Topic < Meth::Plugin

  # initialize
  def initialize *args
    super *args
    @bot.command_manager.register("topic",self)
  end

  # help
  def help(m=nil, topic=nil)
    "topic [message] => Sets the topic to [message]."
  end

  # command called
  def command m
    message = m.params.join(' ')
    if message.length < 1
      m.reply help
      return
    end
    handler = Proc.new{|m2|
      next unless m2.source.nick.downcase == m.source.nick.downcase
      # check response
      case m2.command
      when /yes/i
        m.reply "Changing topic..."
        topic(m.channel.name,message)
      when /no/i
        m.reply "Topic change canceled..."
      else
        m.reply "#{m.source.nick}: Please respond with yes or no..."
        next
      end
      # not yes or topic set
      @bot.event.unregister("meth.command",handler)
    }
    @bot.event.register("meth.command",handler)
    m.reply "Do you really want to change the topic to, \"#{message}\" ?"
  end

  # set topic
  private
  def topic(channel, topic)
    @bot.send_data "TOPIC #{channel} :#{topic}\n"
  end

end
