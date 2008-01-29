class Topic < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("topic",self)
  end

  def help(m=nil, topic=nil)
    "topic [message] => Resets the last section of topic to [message].  "+
    "Topic should be relavant to the current conversations."
  end

  def command m
    # extract message
    topic = m.params.join(' ')
    # insert default message
    if topic.nil? || (topic.length < 1)
      m.reply help
      return false
    end
    # remove special devider ||
    topic.gsub!(/\|+/,'|')
    # format the new topic
    topic = "|| #{topic}"
    # replace user topic section with new topic
    topic = m.channel.topic.gsub(/\|\|.*$/m,topic)
    # set the topic
    @bot.send_data "TOPIC #{m.channel.name} :#{topic}\n"
  end

end
