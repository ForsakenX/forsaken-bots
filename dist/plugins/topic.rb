class Topic < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("topic",self)
  end

  def help(m=nil, topic=nil)
    "topic => Displays the current topic.  "+
    "topic <message> => Resets the user section of the topic to <message>.  "+
    "topic + <message> => Adds <message> to the end of the current topic.  "+
    "topic - <message> => Removes any occurances of <message> in topic.  "+
    "topic r <find> <replace> => Replaces all occurances of <find> with <replace>.  "+
    "Topic should be relavant to the current conversations."
  end

  def command m
    
    # no params passed
    if m.params[0].nil?
      # print topic
      m.reply m.channel.topic
      return
    end

    # extract new topic
    topic = m.params.join(' ').chomp
    
    # remove special devider ||
    topic.gsub!(/\|+/,'|')

    # add to end of topic
    if topic.slice!(/^\+/)
      topic = "#{m.channel.topic} #{topic}"


    else

      # remove substring
      if topic.slice!(/^-/)
        topic = user_part(m.channel.topic).gsub(topic,'')
      
      # find replace
      elsif topic.slice!(/^r/)
        find,replace = topic.split(' ')
        topic = user_part(m.channel.topic).gsub(find,replace)
        

      end

      # default replace user section
      topic = m.channel.topic.gsub(/\|\|.*$/m,"|| #{topic}")

    end
    
    # set the topic
    @bot.send_data "TOPIC #{m.channel.name} :#{topic}\n"

  end

  def user_part topic
    topic.split('||')[1]
  end

end
