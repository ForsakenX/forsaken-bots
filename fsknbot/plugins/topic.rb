class Topic < Irc::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("topic",self)
  end

  def help(m=nil, topic=nil)
    "topic => Displays the current topic.  "+
    "topic <message> => Resets the user section of the topic to <message>.  "+
    "topic +|> <message> => Adds <message> to the end of the current topic.  "+
    "topic r <find> <replace> => Replaces all occurances of <find> with <replace>.  "+
    "Topic should be relavant to the current conversations."
  end

  def command m

    # instance access
    @m = m
    
    # channel only
    unless m.channel
      m.reply "You are not in a channel!"
      return
    end

    # extract new topic
    @topic = m.params.join(' ')

    # no params passed
    if @topic.empty?
      m.reply m.channel.topic
      return
    end

    # catch jack offs
    if @topic == "change me"
      m.reply "change your self numb nutz..."
      return
    end

    # parse switch
    @topic.slice!(/^(r|\+|>|<) /)
    switch = $1

    # handle switch
    case switch

    # find replace
    when "r"
      
      # regex given as needle
      if regex = @topic.slice!(/^\/.+\//m)
        
          find = regex
          replace = @topic.clean_ends

          unless (error = find.test_regex) === true
            @m.reply "Error: Badly formed regex.  "+error
            return
          end

          find = Regexp.new(find.parse_regex)

      # substring given as needle
      else
        find,replace = @topic.split(' ')
      end

      if find.nil?
        @m.reply "Error: Missing <find> or <replace>. "+help(m,:replace)
        return
      end

      find_replace(find,replace)
      replace_user_part
      send_topic


    # append to end
    when ">","+"

      clean_topic
      append_topic
      send_topic

    # prepend to topic
    when "<"

      clean_topic
      prepend_topic
      replace_user_part
      send_topic

    # replace entire user part
    when "",nil

      clean_topic
      replace_user_part
      send_topic

    end
  end

  private

  def send_topic
    @bot.send_data "TOPIC #{@m.channel.name} :#{@topic}\n"
  end

  def user_part
    @m.channel.topic.split('||')[1].clean_ends
  end

  def server_part
    @m.channel.topic.split('||')[0].clean_ends
  end

  def replace_user_part
    @topic = @m.channel.topic.gsub(/\|\|.*$/m,"|| #{@topic}")
  end

  def clean_topic
    @topic.gsub!(/\|+/,'|')
  end

  def append_topic
    @topic = "#{@m.channel.topic} #{@topic}"
  end

  def prepend_topic
    @topic = "#{@topic} #{user_part}"
  end

  def find_replace needle, replace=''
    @topic = user_part.gsub(needle,replace.to_s)
  end

end
