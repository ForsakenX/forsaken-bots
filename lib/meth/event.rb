class Meth::Event
  @@topics = {
    # "something" => [
    #   # callbacks
    # ]
  }
  class << self
    # register to listen to a topic
    def register topic, callback
      @@topics[topic] = [] if @@topics[topic].nil?
      @@topics[topic] << callback
    end
    def unregister topic, callback
      return if @@topics[topic].nil?
      @@topics[topic].delete callback
    end
    # call the callbacks
    def call topic, data
      return if @@topics[topic].nil?
      @@topics[topic].each do |callback|
        callback.call(data)
      end
    end
  end
end
