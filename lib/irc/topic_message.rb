class Irc::TopicMessage < Irc::Message

  attr_reader :user,    # user who set topic if applicable
              :channel, # channel the topic is for
              :topic    # the actual topic

  def initialize(client,line)
    super(client,line)

    # :hostname 332 FsknBot #forsaken :message goes here
    # :hostname TOPIC #forsaken :test4

    unless line =~ /^:[^ ]* (332|TOPIC) ([^#])* *(#[^ ]+) :([^\n]*)/i
      raise "Badly formed topic line"
    end
     
    type    = $1 # 332 or TOPIC
    sender  = $2 #
    channel = $3 #
    topic   = $4 #

    if @channel = @client.channels[channel.downcase]
      @channel.topic = topic
    end

  end
end
