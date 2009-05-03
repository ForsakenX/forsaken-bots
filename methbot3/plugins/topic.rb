
IrcHandleLine.events[:topic].register do |event|
	TopicCommand.set event[:channel], event[:topic]
end

IrcCommandManager.register 'topic' do |m|
  return unless m.channel
  m.reply TopicCommand.get m.to
end

class TopicCommand
class << self
	@@topics = {}
	def set channel, topic
		@@topics[ channel ] = topic
	end
	def get channel
		@@topics[ channel.downcase ]
	end
end
end

