class Meth::Event
  @@topics = {
    # "something" => [
    #   # callbacks
    # ]
  }
  class << self
    # register to listen to a topic
    def register topic, callback
      @@topics[topic] << callback
    end
    def unregister topic, callback
      @@topics[topic].delete callback
    end
    # fire off callbacks from listeners
    def fire topic, data
      @@topics[topic].each do |callback|
        callback.call(data)
      end
    end
  end
end
