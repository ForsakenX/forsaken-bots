class IrcTopic
  class << self

    @topic = ""
    attr_accessor :topic

    def set topic
      IrcConnection.topic topic
    end

    def get
      IrcTopic.topic
    end

  end
end
