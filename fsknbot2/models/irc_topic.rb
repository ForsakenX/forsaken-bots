class IrcTopic
  class << self

    @topic = ""
    attr_accessor :topic

    #
    # Setters
    #

    def set topic
      IrcConnection.topic topic
    end

    def set_user topic
      topic.sub(/^ +/,'').sub(/ +$/,'').gsub(/ +/,' ').gsub(/\|+/,'|')
      set "#{get_server} || #{topic}"
    end

    def prepend_user topic
      set_user "#{topic} #{get_user}" 
    end
  
    def append topic
      set "#{get} #{topic}"
    end

    #
    # Getters
    #  

    def get
      @topic
    end

    def get_user
      get.split('||')[1]
    end
  
    def get_server
      get.split('||')[0]
    end
  
  end
end
