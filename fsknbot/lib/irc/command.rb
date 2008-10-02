class Irc::Command < Irc::PrivMessage

  attr_reader :params, :command

  def initialize *args
    super *args
 
    # look for our nick or target as first word
    # then extract them from the message
    # "(<nick>: |<target>)"

    # Target example
    # ",hi 1 2 3"

    # Directly named example
    # "MethBot: hi 1 2 3"
    
    message = @message.dup
    
    # addressed to my name
    # remove my name and set is_command
    is_command = @named =  !message.slice!(/^#{Regexp.escape(@client.nick)}: /).nil?

    # "hi 1 2 3"
    # now that nick/target is extracted
    # thats how the message looks
    # includes the command and params

    # if its a pm then its allways a command
    is_command = @personal if !is_command

    # %w{hi 1 2 3}
    # split words in line
    @params = message.split(' ')

    # "hi"
    # the command
    @command = params.shift

    # message is now the command + params
    # @command is now the command
    # @params is now an array of words after the command

    # call easy to use command event
    if @command
      LOGGER.info("meth.command #{command.downcase}")
      @client.event.call("meth.command",self)
      @client.event.call("meth.command.#{command.downcase}",self)
    end

  end

end
