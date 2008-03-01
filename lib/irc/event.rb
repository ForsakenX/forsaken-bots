class Irc::Event
  attr_reader :topics
  def initialize
    @topics = Hash.new {|h,k| h[k] = {0=>[]}}
  end
  # register to listen to a topic
  def register topic, callback, place=0
    @topics[topic] << callback
  end
  # unregister to listen to a topic
  def unregister topic, callback
    @topics[topic].delete callback
  end
  # call the callbacks
  def call topic, data
    @topics[topic].dup.each do |callback|
      begin
        callback.call(data) unless callback.nil?
      rescue Exception
        Irc::Client.logger.error "#{$!}\n#{$@.join("\n")}"
      end
    end
  end
end
